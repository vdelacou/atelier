// minimal router stub: handlers get the request and a context with verified claims
export type Claims = { readonly sub: string; readonly org_id: string };
export type Ctx = { readonly claims: Claims; readonly params: Readonly<Record<string, string>> };
export type Handler = (req: Request, ctx: Ctx) => Promise<Response>;
export const routes: Record<string, Handler> = {};
export const register = (path: string, handler: Handler): void => { routes[path] = handler; };
