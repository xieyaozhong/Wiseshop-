// Supabase Edge Function: LINE Messaging API webhook
// Secret required: LINE_CHANNEL_SECRET
// Optional: N8N_WEBHOOK_URL for forwarding verified events to an automation workflow.

function base64ToBytes(value: string) {
  const bin = atob(value);
  return Uint8Array.from(bin, c => c.charCodeAt(0));
}

async function verifyLineSignature(raw: string, signature: string, secret: string) {
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['verify'],
  );
  return crypto.subtle.verify(
    'HMAC',
    key,
    base64ToBytes(signature),
    new TextEncoder().encode(raw),
  );
}

Deno.serve(async (req) => {
  if (req.method !== 'POST') return new Response('POST only', { status: 405 });

  const secret = Deno.env.get('LINE_CHANNEL_SECRET');
  if (!secret) return new Response('LINE webhook not configured', { status: 503 });

  const signature = req.headers.get('x-line-signature') ?? '';
  const raw = await req.text();
  const ok = signature && await verifyLineSignature(raw, signature, secret).catch(() => false);
  if (!ok) return new Response('invalid signature', { status: 401 });

  const payload = JSON.parse(raw);
  const n8n = Deno.env.get('N8N_WEBHOOK_URL');

  // Forward only after signature verification. n8n can fan out to CRM, notifications,
  // order capture or human-approval workflows.
  if (n8n && Array.isArray(payload.events)) {
    await Promise.allSettled(payload.events.map((event: unknown) => fetch(n8n, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ source: 'line', event }),
    })));
  }

  return Response.json({ ok: true });
});
