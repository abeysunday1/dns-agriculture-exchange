import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const reply = (body: Record<string, unknown>, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return reply({ error: "Method not allowed" }, 405);

  const authorization = req.headers.get("Authorization");
  const token = authorization?.replace(/^Bearer\s+/i, "");
  if (!authorization || !token) return reply({ error: "Authentication required" }, 401);

  const url = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !anonKey || !serviceKey) return reply({ error: "Server configuration unavailable" }, 500);

  const caller = createClient(url, anonKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: { user }, error: userError } = await caller.auth.getUser(token);
  if (userError || !user) return reply({ error: "Invalid session" }, 401);

  const { data: isAdmin, error: adminError } = await caller.rpc("is_exchange_admin");
  if (adminError || isAdmin !== true) return reply({ error: "Administrator access required" }, 403);

  let requestId: string;
  try {
    const body = await req.json();
    requestId = String(body?.request_id || "");
  } catch {
    return reply({ error: "Invalid JSON body" }, 400);
  }
  if (!/^[0-9a-f-]{36}$/i.test(requestId)) return reply({ error: "Invalid request_id" }, 400);

  const service = createClient(url, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: request, error: requestError } = await service
    .from("account_deletion_requests")
    .select("id,user_id,status")
    .eq("id", requestId)
    .maybeSingle();

  if (requestError || !request) return reply({ error: "Deletion request not found" }, 404);
  if (request.status !== "approved" || !request.user_id) {
    return reply({ error: "Request is not approved or has already been processed" }, 409);
  }

  // Supabase Admin signOut requires the target user's JWT, not their user ID.
  // deleteUser removes auth.sessions/refresh tokens; session-aware RLS blocks any
  // already-issued access JWT from accessing exchange data before its expiry.
  const { error: deleteError } = await service.auth.admin.deleteUser(request.user_id);
  if (deleteError) return reply({ error: "Auth deletion failed", detail: deleteError.message }, 500);

  return reply({ success: true, request_id: requestId, auth_user_deleted: true });
});
