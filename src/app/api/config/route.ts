import { NextResponse } from "next/server";

/**
 * Returns the public-safe portion of the proxy config. The base URL is fine
 * to expose (it's just a URL); the API key stays server-side and is never
 * surfaced here. The 'Call this agent' snippet card uses base_url to show
 * users the actual URL they'd hit from outside the app — so the snippets
 * remain accurate without leaking secrets.
 */

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function GET() {
  return NextResponse.json({
    base_url: process.env.LITELLM_BASE_URL ?? "",
  });
}
