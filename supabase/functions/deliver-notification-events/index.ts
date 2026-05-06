import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-ingest-secret",
};

type NotificationEventRow = {
  id: string;
  user_id: string;
  payload: Record<string, unknown>;
};

type PushTokenRow = {
  token: string;
  platform: string;
};

function toInt(value: unknown, fallback: number): number {
  const n = Number(value);
  if (!Number.isFinite(n) || n <= 0) return fallback;
  return Math.trunc(n);
}

function buildBody(payload: Record<string, unknown>): string {
  const savings = payload.savings_yen;
  const productName = payload.product_name;
  if (typeof savings === "number" && typeof productName === "string") {
    return `${productName} が ${savings}円安い特売に出ています`;
  }
  return "ウォッチ中商品の特売が見つかりました";
}

async function sendToFcm(
  serverKey: string,
  token: string,
  payload: Record<string, unknown>,
): Promise<{ ok: boolean; detail?: string }> {
  const body = {
    to: token,
    priority: "high",
    notification: {
      title: "値下がり通知",
      body: buildBody(payload),
    },
    data: {
      type: "cheaper_than_last",
      product_name: String(payload.product_name ?? ""),
      savings_yen: String(payload.savings_yen ?? ""),
    },
  };
  const res = await fetch("https://fcm.googleapis.com/fcm/send", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `key=${serverKey}`,
    },
    body: JSON.stringify(body),
  });
  if (!res.ok) {
    return { ok: false, detail: `http_${res.status}` };
  }
  const data = await res.json();
  if (data?.failure && Number(data.failure) > 0) {
    const err = data?.results?.[0]?.error;
    return { ok: false, detail: typeof err === "string" ? err : "fcm_failure" };
  }
  return { ok: true };
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

  const fcmServerKey = Deno.env.get("FCM_SERVER_KEY");
  if (!fcmServerKey) {
    return new Response(JSON.stringify({ error: "FCM_SERVER_KEY is not set" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const url = Deno.env.get("SUPABASE_URL")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const supabase = createClient(url, serviceKey);

  let limit = 50;
  try {
    const body = await req.json();
    limit = toInt(body?.limit, 50);
  } catch {
    // body optional
  }

  const { data: eventRows, error: eventError } = await supabase
    .from("notification_events")
    .select("id, user_id, payload")
    .eq("status", "queued")
    .order("created_at", { ascending: true })
    .limit(limit);
  if (eventError) {
    return new Response(JSON.stringify({ error: eventError.message }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const events = (eventRows ?? []) as NotificationEventRow[];
  if (events.length === 0) {
    return new Response(JSON.stringify({ delivered: 0, failed: 0, skipped: 0 }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  let delivered = 0;
  let failed = 0;
  let skipped = 0;

  for (const event of events) {
    const { data: tokensData, error: tokenError } = await supabase
      .from("user_push_tokens")
      .select("token, platform")
      .eq("user_id", event.user_id)
      .eq("enabled", true);
    if (tokenError) {
      failed += 1;
      await supabase
        .from("notification_events")
        .update({
          status: "failed",
          payload: { ...event.payload, delivery_error: tokenError.message },
        })
        .eq("id", event.id);
      continue;
    }

    const tokens = (tokensData ?? []) as PushTokenRow[];
    if (tokens.length === 0) {
      skipped += 1;
      await supabase
        .from("notification_events")
        .update({
          status: "skipped",
          payload: { ...event.payload, delivery_error: "no_enabled_tokens" },
        })
        .eq("id", event.id);
      continue;
    }

    const sendResults = await Promise.all(
      tokens.map((t) => sendToFcm(fcmServerKey, t.token, event.payload ?? {})),
    );
    const hasSuccess = sendResults.some((r) => r.ok);
    if (hasSuccess) {
      delivered += 1;
      await supabase
        .from("notification_events")
        .update({ status: "delivered", delivered_at: new Date().toISOString() })
        .eq("id", event.id);
    } else {
      failed += 1;
      const detail = sendResults.map((r) => r.detail).filter(Boolean).join(",");
      await supabase
        .from("notification_events")
        .update({
          status: "failed",
          payload: { ...event.payload, delivery_error: detail || "send_failed" },
        })
        .eq("id", event.id);
    }
  }

  return new Response(JSON.stringify({ delivered, failed, skipped }), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
