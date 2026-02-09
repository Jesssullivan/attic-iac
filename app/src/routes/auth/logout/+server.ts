import { redirect } from "@sveltejs/kit";
import { getSession, clearSession } from "$lib/server/auth/session";
import { revokeToken } from "$lib/server/auth/gitlab-oauth";
import type { RequestHandler } from "./$types";

export const GET: RequestHandler = async ({ cookies }) => {
  const session = getSession(cookies);
  if (session?.access_token) {
    await revokeToken(session.access_token);
  }
  clearSession(cookies);
  redirect(302, "/auth/logged-out");
};
