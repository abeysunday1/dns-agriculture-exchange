import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json"
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return new Response(JSON.stringify({ error: "Method not allowed" }), { status: 405, headers: cors });

  const authorization = req.headers.get("Authorization");
  if (!authorization) return new Response(JSON.stringify({ error: "Authentication required" }), { status: 401, headers: cors });

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !anonKey || !serviceRoleKey) return new Response(JSON.stringify({ error: "Server configuration unavailable" }), { status: 500, headers: cors });

  const userClient = createClient(supabaseUrl, anonKey, { global: { headers: { Authorization: authorization } } });
  const { data: authData, error: authError } = await userClient.auth.getUser();
  if (authError || !authData.user) return new Response(JSON.stringify({ error: "Invalid session" }), { status: 401, headers: cors });

  let body: { submission_id?: string };
  try { body = await req.json(); } catch { return new Response(JSON.stringify({ error: "Invalid JSON" }), { status: 400, headers: cors }); }
  if (!body.submission_id) return new Response(JSON.stringify({ error: "submission_id is required" }), { status: 400, headers: cors });

  const { data: submission, error: submissionError } = await userClient
    .from("exchange_submissions")
    .select("id,user_id,submission_type,created_at")
    .eq("id", body.submission_id)
    .single();

  if (submissionError || !submission || submission.user_id !== authData.user.id) {
    return new Response(JSON.stringify({ error: "Submission not found for this account" }), { status: 404, headers: cors });
  }

  const serviceClient = createClient(supabaseUrl, serviceRoleKey);
  const { data: hookSecret, error: secretError } = await serviceClient.rpc("get_exchange_hook_secret");
  if (secretError || !hookSecret) return new Response(JSON.stringify({ error: "Automation secret unavailable" }), { status: 500, headers: cors });

  const hookResponse = await fetch("https://cloud.activepieces.com/api/v1/webhooks/zzTDrvGsMPvjq1u1cxwhU", {
    method: "POST",
    headers: { "Content-Type": "application/json", "x-dns-exchange-key": hookSecret },
    body: JSON.stringify({
      submission_id: submission.id,
      user_id: submission.user_id,
      submission_type: submission.submission_type,
      created_at: submission.created_at
    })
  });

  if (!hookResponse.ok) {
    return new Response(JSON.stringify({ error: "Submission saved, but automation delivery failed", automation_status: "pending_retry" }), { status: 502, headers: cors });
  }

  return new Response(JSON.stringify({ ok: true, automation_status: "delivered" }), { status: 200, headers: cors });
});