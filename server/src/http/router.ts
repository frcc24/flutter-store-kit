import { internalRetryable, methodNotAllowed, notFound } from './problem.js';

export interface RouteContext {
  readonly request: Request;
  readonly env: Env;
  readonly ctx: ExecutionContext;
  readonly params: Readonly<Record<string, string>>;
  readonly url: URL;
}

export type RouteHandler = (context: RouteContext) => Promise<Response> | Response;

interface Route {
  readonly method: string;
  readonly pattern: URLPattern;
  readonly handler: RouteHandler;
}

/// Minimal router over the runtime's own `URLPattern`.
///
/// ponytail: no routing dependency. Exact paths are all this API has, and
/// `URLPattern` is built into the Workers runtime. 404 and 405 are told apart
/// on purpose: a real path with the wrong method is a client bug worth seeing.
export class Router {
  private readonly routes: Route[] = [];

  add(method: string, pathname: string, handler: RouteHandler): this {
    this.routes.push({ method, pattern: new URLPattern({ pathname }), handler });
    return this;
  }

  get(pathname: string, handler: RouteHandler): this {
    return this.add('GET', pathname, handler);
  }

  post(pathname: string, handler: RouteHandler): this {
    return this.add('POST', pathname, handler);
  }

  async handle(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    const url = new URL(request.url);
    let pathMatched = false;
    for (const route of this.routes) {
      const match = route.pattern.exec(url);
      if (match === null) continue;
      pathMatched = true;
      const method = request.method === 'HEAD' ? 'GET' : request.method;
      if (route.method !== method) continue;
      const params: Record<string, string> = {};
      for (const [key, value] of Object.entries(match.pathname.groups)) {
        if (value !== undefined) params[key] = value;
      }
      try {
        return await route.handler({ request, env, ctx, params, url });
      } catch (error) {
        // Never an opaque 500 with a stack in the body: log the pathname
        // (never the query — the Unity signature travels there) and hand the
        // client a retryable code.
        console.error('unhandled_route_error', url.pathname, String(error).slice(0, 200));
        return internalRetryable();
      }
    }
    return pathMatched ? methodNotAllowed() : notFound();
  }
}
