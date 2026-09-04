// Supabase Edge Function: WiseShop AI Copilot
// Secrets required: OPENAI_API_KEY, OPENAI_MODEL
// Keep this server-side. Never expose OpenAI secrets in GitHub Pages.

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });
  if (req.method !== 'POST') return Response.json({ error: 'POST only' }, { status: 405, headers: cors });

  const apiKey = Deno.env.get('OPENAI_API_KEY');
  const model = Deno.env.get('OPENAI_MODEL');
  if (!apiKey || !model) return Response.json({ error: 'AI backend is not configured' }, { status: 503, headers: cors });

  const body = await req.json().catch(() => ({}));
  const message = String(body.message ?? '').slice(0, 4000);
  const context = body.context ?? {};
  if (!message) return Response.json({ error: 'message is required' }, { status: 400, headers: cors });

  // Only send the minimum operational summary needed for this question.
  // Raw customer PII should stay out unless the shop explicitly needs it.
  const system = `你是「店智 AI」店長助理。你服務台灣小微店家。\n` +
    `回答要簡短、可行動、用繁體中文。不得假造資料。\n` +
    `如果建議會造成付款、發訊息、改庫存、刪資料等外部動作，只能提出建議，必須等待人工確認。`;

  const input = `${system}\n\n店內摘要(JSON)：${JSON.stringify(context).slice(0, 12000)}\n\n店長問題：${message}`;

  const upstream = await fetch('https://api.openai.com/v1/responses', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ model, input }),
  });

  const data = await upstream.json().catch(() => ({}));
  if (!upstream.ok) return Response.json({ error: 'AI request failed', detail: data }, { status: 502, headers: cors });

  const text = (data.output ?? [])
    .flatMap((item: any) => item.content ?? [])
    .find((c: any) => c.type === 'output_text')?.text ?? '';

  return Response.json({ text, response_id: data.id }, { headers: { ...cors, 'Content-Type': 'application/json' } });
});
