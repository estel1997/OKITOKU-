import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-ingest-secret",
};

type IngestFlyerAssetBody = {
  filename: string;
  content_base64: string;
  content_type: string;
};

const kAllowedContentTypes = new Set<string>([
  "image/jpeg",
  "image/jpg",
  "application/pdf",
]);

function decodeBase64Payload(raw: string): Uint8Array {
  const payload = raw.includes(",") ? raw.split(",").pop() ?? "" : raw;
  return Uint8Array.from(atob(payload), (c) => c.charCodeAt(0));
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
  if (!ingestSecret || ingestSecret.length < 8) {
    return new Response(
      JSON.stringify({
        error:
          "Server misconfiguration: set INGEST_SECRET (Dashboard → Edge Functions → Secrets)",
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

  let body: IngestFlyerAssetBody;
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  if (!body.filename || typeof body.filename !== "string") {
    return new Response(JSON.stringify({ error: "filename is required" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
  if (!body.content_base64 || typeof body.content_base64 !== "string") {
    return new Response(JSON.stringify({ error: "content_base64 is required" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
  if (!kAllowedContentTypes.has(body.content_type)) {
    return new Response(
      JSON.stringify({
        error: "content_type must be image/jpeg, image/jpg, or application/pdf",
      }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  const bytes = decodeBase64Payload(body.content_base64);
  const safeName = body.filename.replace(/[^a-zA-Z0-9._-]/g, "_");
  const datePrefix = new Date().toISOString().slice(0, 10);
  const path = `${datePrefix}/${crypto.randomUUID()}-${safeName}`;

  const url = Deno.env.get("SUPABASE_URL")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const supabase = createClient(url, serviceKey);

  const { error } = await supabase.storage
    .from("flyer_sources")
    .upload(path, bytes, {
      contentType: body.content_type,
      upsert: false,
    });

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  return new Response(
    JSON.stringify({
      bucket: "flyer_sources",
      path,
      source_ref: `storage://flyer_sources/${path}`,
      content_type: body.content_type,
      bytes: bytes.byteLength,
    }),
    { headers: { ...corsHeaders, "Content-Type": "application/json" } },
  );
});
