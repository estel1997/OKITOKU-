import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type ProductRow = { id: string; canonical_name: string };
type ObservationRow = {
  id: string;
  product_id: string;
  store_id: string | null;
  price_yen: number;
  observed_at: string;
  source: string;
  stores?: { name?: string | null } | null;
};
type FlyerRow = {
  id: string;
  product_name: string;
  chain_id: string | null;
  store_id: string | null;
  price_yen: number | null;
  valid_from: string | null;
  valid_to: string | null;
  ingestion_source: string;
  source_ref: string | null;
};

function containsProductName(flyerName: string, canonicalName: string): boolean {
  return flyerName.includes(canonicalName);
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const url = Deno.env.get("SUPABASE_URL")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const userClient = createClient(url, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const {
    data: { user },
    error: userError,
  } = await userClient.auth.getUser();
  if (userError || !user) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const supabase = createClient(url, serviceKey);
  const { data: watchRow, error: watchError } = await supabase
    .from("user_watch_products")
    .select("product_ids")
    .eq("user_id", user.id)
    .maybeSingle();
  if (watchError) {
    return new Response(JSON.stringify({ error: watchError.message }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const watchedProductIds = Array.isArray(watchRow?.product_ids)
    ? watchRow!.product_ids.map((x: unknown) => String(x))
    : [];
  if (watchedProductIds.length === 0) {
    return new Response(JSON.stringify({ hits: [] }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const { data: productRows, error: productsError } = await supabase
    .from("products")
    .select("id, canonical_name")
    .in("id", watchedProductIds);
  if (productsError) {
    return new Response(JSON.stringify({ error: productsError.message }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
  const products = (productRows ?? []) as ProductRow[];
  if (products.length === 0) {
    return new Response(JSON.stringify({ hits: [] }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const nowIso = new Date().toISOString();
  const { data: observationRows, error: obsError } = await supabase
    .from("product_price_observations")
    .select("id, product_id, store_id, price_yen, observed_at, source, stores(name)")
    .in("product_id", watchedProductIds)
    .order("observed_at", { ascending: false });
  if (obsError) {
    return new Response(JSON.stringify({ error: obsError.message }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
  const latestByProduct = new Map<string, ObservationRow>();
  for (const row of (observationRows ?? []) as ObservationRow[]) {
    if (!latestByProduct.has(row.product_id)) {
      latestByProduct.set(row.product_id, row);
    }
  }
  if (latestByProduct.size === 0) {
    return new Response(JSON.stringify({ hits: [] }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  let flyersQuery = supabase
    .from("flyer_offers")
    .select("id, product_name, chain_id, store_id, price_yen, valid_from, valid_to, ingestion_source, source_ref")
    .not("price_yen", "is", null);
  flyersQuery = flyersQuery.or(`valid_from.is.null,valid_from.lte.${nowIso}`);
  flyersQuery = flyersQuery.or(`valid_to.is.null,valid_to.gte.${nowIso}`);
  const { data: flyerRows, error: flyerError } = await flyersQuery.order("created_at", {
    ascending: false,
  });
  if (flyerError) {
    return new Response(JSON.stringify({ error: flyerError.message }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const bestByProduct = new Map<string, {
    product: ProductRow;
    offer: FlyerRow;
    last_observation: ObservationRow;
    savings_yen: number;
  }>();
  const flyers = (flyerRows ?? []) as FlyerRow[];
  for (const offer of flyers) {
    if (offer.price_yen == null) continue;
    let matched: ProductRow | null = null;
    for (const p of products) {
      if (!containsProductName(offer.product_name, p.canonical_name)) {
        continue;
      }
      if (matched == null || p.canonical_name.length > matched.canonical_name.length) {
        matched = p;
      }
    }
    if (!matched) continue;
    const last = latestByProduct.get(matched.id);
    if (!last || offer.price_yen >= last.price_yen) continue;
    const savings = last.price_yen - offer.price_yen;
    const existing = bestByProduct.get(matched.id);
    if (!existing || savings > existing.savings_yen) {
      bestByProduct.set(matched.id, {
        product: matched,
        offer,
        last_observation: last,
        savings_yen: savings,
      });
    }
  }

  const hits = [...bestByProduct.values()].sort((a, b) => b.savings_yen - a.savings_yen);
  return new Response(JSON.stringify({ hits }), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
