import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-ingest-secret",
};

type ObservationInput = {
  id?: string;
  product_id: string;
  store_id?: string | null;
  price_yen: number;
  observed_at?: string | null;
  source?: string | null;
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

  if (req.headers.get("x-ingest-secret") !== ingestSecret) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  let body: { observations?: ObservationInput[] };
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const items = body.observations;
  if (!Array.isArray(items) || items.length === 0) {
    return new Response(JSON.stringify({ error: "observations must be a non-empty array" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const rows: Record<string, unknown>[] = [];
  for (const o of items) {
    if (!o.product_id || typeof o.product_id !== "string") {
      return new Response(JSON.stringify({ error: "Each row needs product_id (string)" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    if (typeof o.price_yen !== "number" || o.price_yen < 0) {
      return new Response(JSON.stringify({ error: "Each row needs price_yen (number >= 0)" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    const row: Record<string, unknown> = {
      product_id: o.product_id.trim(),
      store_id: o.store_id ?? null,
      price_yen: o.price_yen,
      observed_at: o.observed_at ?? new Date().toISOString(),
      source: (o.source ?? "manual").trim(),
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
    .from("product_price_observations")
    .upsert(rows, {
      onConflict: "product_id,store_id,price_yen,observed_at,source",
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
