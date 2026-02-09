import { redirect } from "@sveltejs/kit";
import { clearSession } from "$lib/server/auth/session";
import type { RequestHandler } from "./$types";

export const GET: RequestHandler = async ({ cookies }) => {
  clearSession(cookies);
  redirect(302, "/auth/login");
};
