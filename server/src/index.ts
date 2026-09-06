export default {
  async fetch(request: Request, _env: Env): Promise<Response> {
    if (new URL(request.url).pathname === '/v1/health') {
      return new Response(JSON.stringify({ ok: true }), { headers: { 'content-type': 'application/json' } });
    }
    return new Response('not found', { status: 404 });
  },
};
