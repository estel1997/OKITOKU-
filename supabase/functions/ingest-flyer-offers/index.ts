import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-ingest-secret",
};

type FlyerOfferInput = {
  id?: string;
  product_name: string;
  chain_id?: string | null;
  store_id?: string | null;
  price_yen?: number | null;
  valid_from?: string | null;
  valid_to?: string | null;
  ingestion_source: string;
  source_ref?: string | null;
};

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
  if (!ingestSecret || ingestSecret.length < 8) {
    return new Response(
      JSON.stringify({
        error: "Server misconfiguration: set INGEST_SECRET (Dashboard → Edge Functions → Secrets)",
      }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  const headerSecret = req.headers.get("x-ingest-secret");
  if (headerSecret !== ingestSecret) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  let body: { offers?: FlyerOfferInput[] };
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const offers = body.offers;
  if (!Array.isArray(offers) || offers.length === 0) {
    return new Response(JSON.stringify({ error: "offers must be a non-empty array" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const rows: Record<string, unknown>[] = [];
  for (const o of offers) {
    if (!o.product_name || typeof o.product_name !== "string") {
      return new Response(JSON.stringify({ error: "Each offer needs product_name (string)" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    if (!o.ingestion_source || typeof o.ingestion_source !== "string") {
      return new Response(JSON.stringify({ error: "Each offer needs ingestion_source (string)" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    const row: Record<string, unknown> = {
      product_name: o.product_name.trim(),
      chain_id: o.chain_id ?? null,
      store_id: o.store_id ?? null,
      price_yen: o.price_yen ?? null,
      valid_from: o.valid_from ?? null,
      valid_to: o.valid_to ?? null,
      ingestion_source: o.ingestion_source.trim(),
      source_ref: o.source_ref ?? null,
    };
    if (o.id) {
      row.id = o.id;
    }
    rows.push(row);
  }

  const url = Deno.env.get("SUPABASE_URL")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const supabase = createClient(url, serviceKey);

  const { data, error } = await supabase
    .from("flyer_offers")
    .upsert(rows, {
      onConflict: "ingestion_source,source_ref",
      ignoreDuplicates: true,
    })
    .select("id");

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const ids = Array.isArray(data)
    ? data.map((r: { id: string }) => r.id)
    : [];

  return new Response(
    JSON.stringify({ inserted: data?.length ?? rows.length, ids }),
    { headers: { ...corsHeaders, "Content-Type": "application/json" } },
  );
});
