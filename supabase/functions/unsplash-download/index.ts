// Tells Unsplash that a photo was used in SHOTBOOK (saved or opened in
// "Repeat this shot"), as the Unsplash API guidelines require
// ("trigger downloads"). The Access Key stays on the server.
//
// Secret: UNSPLASH_ACCESS_KEY (supabase secrets set UNSPLASH_ACCESS_KEY=...)
// Body: { "id": "<unsplash photo id>" }

const ID_PATTERN = /^[A-Za-z0-9_-]{6,32}$/;

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405, headers: cors });
  }
  const key = Deno.env.get("UNSPLASH_ACCESS_KEY");
  if (!key) return new Response("Not configured", { status: 503, headers: cors });

  let id: unknown;
  try {
    ({ id } = await req.json());
  } catch {
    return new Response("Bad request", { status: 400, headers: cors });
  }
  if (typeof id !== "string" || !ID_PATTERN.test(id)) {
    return new Response("Bad photo id", { status: 400, headers: cors });
  }

  const res = await fetch(
    `https://api.unsplash.com/photos/${encodeURIComponent(id)}/download`,
    { headers: { Authorization: `Client-ID ${key}`, "Accept-Version": "v1" } },
  );
  return new Response(JSON.stringify({ ok: res.ok }), {
    status: res.ok ? 200 : 502,
    headers: { ...cors, "Content-Type": "application/json" },
  });
});
