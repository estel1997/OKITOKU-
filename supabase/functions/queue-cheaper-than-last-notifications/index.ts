import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-ingest-secret",
};

type ProductRow = { id: string; canonical_name: string };
type ObservationRow = {
  id: string;
  product_id: string;
  price_yen: number;
  observed_at: string;
};
type FlyerRow = {
  id: string;
  product_name: string;
  price_yen: number | null;
  valid_from: string | null;
  valid_to: string | null;
};
type WatchRow = { user_id: string; product_ids: string[] };

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

  const ingestSecret = Deno.env.get("INGEST_SECRET");
  if (!ingestSecret || req.headers.get("x-ingest-secret") !== ingestSecret) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const url = Deno.env.get("SUPABASE_URL")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const supabase = createClient(url, serviceKey);
  const nowIso = new Date().toISOString();

  const { data: watchRows, error: watchError } = await supabase
    .from("user_watch_products")
    .select("user_id, product_ids");
  if (watchError) {
    return new Response(JSON.stringify({ error: watchError.message }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
  const watches = (watchRows ?? []) as WatchRow[];
  const allProductIds = [...new Set(watches.flatMap((w) => w.product_ids ?? []))];
  if (allProductIds.length === 0) {
    return new Response(JSON.stringify({ queued: 0 }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const { data: productsData, error: productsError } = await supabase
    .from("products")
    .select("id, canonical_name")
    .in("id", allProductIds);
  if (productsError) {
    return new Response(JSON.stringify({ error: productsError.message }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
  const products = (productsData ?? []) as ProductRow[];
  const productsById = new Map(products.map((p) => [p.id, p]));

  const { data: obsData, error: obsError } = await supabase
    .from("product_price_observations")
    .select("id, product_id, price_yen, observed_at")
    .in("product_id", allProductIds)
    .order("observed_at", { ascending: false });
  if (obsError) {
    return new Response(JSON.stringify({ error: obsError.message }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
  const latestObsByProduct = new Map<string, ObservationRow>();
  for (const row of (obsData ?? []) as ObservationRow[]) {
    if (!latestObsByProduct.has(row.product_id)) {
      latestObsByProduct.set(row.product_id, row);
    }
  }

  let flyersQuery = supabase
    .from("flyer_offers")
    .select("id, product_name, price_yen, valid_from, valid_to")
    .not("price_yen", "is", null);
  flyersQuery = flyersQuery.or(`valid_from.is.null,valid_from.lte.${nowIso}`);
  flyersQuery = flyersQuery.or(`valid_to.is.null,valid_to.gte.${nowIso}`);
  const { data: flyerData, error: flyerError } = await flyersQuery.order("created_at", {
    ascending: false,
  });
  if (flyerError) {
    return new Response(JSON.stringify({ error: flyerError.message }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
  const flyers = (flyerData ?? []) as FlyerRow[];

  const rowsToInsert: Record<string, unknown>[] = [];
  for (const w of watches) {
    const productIds = Array.isArray(w.product_ids) ? w.product_ids : [];
    if (productIds.length === 0) continue;

    for (const pid of productIds) {
      const product = productsById.get(pid);
      const last = latestObsByProduct.get(pid);
      if (!product || !last) continue;

      let bestOffer: FlyerRow | null = null;
      let bestSavings = 0;
      for (const offer of flyers) {
        if (offer.price_yen == null) continue;
        if (!containsProductName(offer.product_name, product.canonical_name)) continue;
        const savings = last.price_yen - offer.price_yen;
        if (savings > bestSavings) {
          bestSavings = savings;
          bestOffer = offer;
        }
      }
      if (!bestOffer || bestSavings <= 0) continue;
      rowsToInsert.push({
        user_id: w.user_id,
        product_id: pid,
        flyer_offer_id: bestOffer.id,
        observation_id: last.id,
        savings_yen: bestSavings,
        status: "queued",
        payload: {
          product_name: product.canonical_name,
          offer_price_yen: bestOffer.price_yen,
          last_price_yen: last.price_yen,
          savings_yen: bestSavings,
        },
      });
    }
  }

  if (rowsToInsert.length == 0) {
    return new Response(JSON.stringify({ queued: 0 }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const { data: inserted, error: insertError } = await supabase
    .from("notification_events")
    .upsert(rowsToInsert, {
      onConflict: "user_id,product_id,flyer_offer_id,observation_id",
      ignoreDuplicates: true,
    })
    .select("id");
  if (insertError) {
    return new Response(JSON.stringify({ error: insertError.message }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  return new Response(JSON.stringify({ queued: inserted?.length ?? rowsToInsert.length }), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
