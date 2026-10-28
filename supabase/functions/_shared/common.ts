import { createClient, SupabaseClient } from "npm:@supabase/supabase-js@2";

export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

/** Client dengan service role: hanya dipakai di server (Edge Function). */
export function adminClient(): SupabaseClient {
  return createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
}

/**
 * Pastikan pemanggil adalah pengguna yang sudah login. Anon key (yang publik
 * di dalam aplikasi) saja TIDAK cukup, jadi orang luar tidak bisa memakai
 * kuota Gemini / wallet kita.
 */
export async function requireUser(
  req: Request,
  admin: SupabaseClient,
): Promise<string | null> {
  const token = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
  if (!token) return null;
  const { data, error } = await admin.auth.getUser(token);
  if (error || !data.user) return null;
  return data.user.id;
}

/** Batas pemakaian per pengguna. True = masih boleh. */
export async function underLimit(
  admin: SupabaseClient,
  userId: string,
  kind: string,
  max: number,
  windowSeconds: number,
): Promise<boolean> {
  const since = new Date(Date.now() - windowSeconds * 1000).toISOString();
  const { count } = await admin
    .from("usage_log")
    .select("id", { count: "exact", head: true })
    .eq("user_id", userId)
    .eq("kind", kind)
    .gte("created_at", since);
  return (count ?? 0) < max;
}

export async function logUsage(
  admin: SupabaseClient,
  userId: string,
  kind: string,
): Promise<void> {
  await admin.from("usage_log").insert({ user_id: userId, kind });
}
