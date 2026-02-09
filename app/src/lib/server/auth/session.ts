import type { Cookies } from "@sveltejs/kit";

const SESSION_COOKIE = "dashboard_session";
const SESSION_MAX_AGE = 60 * 60 * 8; // 8 hours

export interface Session {
  access_token: string;
  refresh_token: string;
  expires_at: number;
  user: {
    id: number;
    username: string;
    name: string;
    email: string;
    role: "viewer" | "operator" | "admin";
  };
}

export function getSession(cookies: Cookies): Session | null {
  const raw = cookies.get(SESSION_COOKIE);
  if (!raw) return null;

  try {
    const decoded = Buffer.from(raw, "base64").toString("utf-8");
    return JSON.parse(decoded) as Session;
  } catch {
    return null;
  }
}

export function setSession(cookies: Cookies, session: Session) {
  const encoded = Buffer.from(JSON.stringify(session)).toString("base64");
  cookies.set(SESSION_COOKIE, encoded, {
    path: "/",
    httpOnly: true,
    secure: true,
    sameSite: "lax",
    maxAge: SESSION_MAX_AGE,
  });
}

export function clearSession(cookies: Cookies) {
  cookies.delete(SESSION_COOKIE, {
    path: "/",
    secure: true,
    sameSite: "lax",
  });
}
