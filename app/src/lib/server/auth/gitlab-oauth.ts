import { env } from "$env/dynamic/private";

export interface OAuthConfig {
  clientId: string;
  clientSecret: string;
  redirectUri: string;
  gitlabUrl: string;
}

function getConfig(): OAuthConfig {
  return {
    clientId: env.GITLAB_OAUTH_CLIENT_ID ?? "",
    clientSecret: env.GITLAB_OAUTH_CLIENT_SECRET ?? "",
    redirectUri:
      env.GITLAB_OAUTH_REDIRECT_URI ?? "http://localhost:3000/auth/callback",
    gitlabUrl: env.GITLAB_URL ?? "https://gitlab.com",
  };
}

export function getAuthorizeUrl(state: string): string {
  const config = getConfig();
  const params = new URLSearchParams({
    client_id: config.clientId,
    redirect_uri: config.redirectUri,
    response_type: "code",
    scope: "read_api",
    state,
  });
  return `${config.gitlabUrl}/oauth/authorize?${params}`;
}

export async function exchangeCode(code: string): Promise<{
  access_token: string;
  refresh_token: string;
  expires_in: number;
}> {
  const config = getConfig();
  const response = await fetch(`${config.gitlabUrl}/oauth/token`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      client_id: config.clientId,
      client_secret: config.clientSecret,
      code,
      grant_type: "authorization_code",
      redirect_uri: config.redirectUri,
    }),
  });

  if (!response.ok) {
    throw new Error(`OAuth token exchange failed: ${response.status}`);
  }

  return response.json();
}

export async function refreshAccessToken(refreshToken: string): Promise<{
  access_token: string;
  refresh_token: string;
  expires_in: number;
}> {
  const config = getConfig();
  const response = await fetch(`${config.gitlabUrl}/oauth/token`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      client_id: config.clientId,
      client_secret: config.clientSecret,
      refresh_token: refreshToken,
      grant_type: "refresh_token",
    }),
  });

  if (!response.ok) {
    throw new Error(`OAuth token refresh failed: ${response.status}`);
  }

  return response.json();
}

export async function revokeToken(token: string): Promise<void> {
  const config = getConfig();
  try {
    await fetch(`${config.gitlabUrl}/oauth/revoke`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        client_id: config.clientId,
        client_secret: config.clientSecret,
        token,
      }),
    });
  } catch {
    // Best-effort revocation; don't block logout
  }
}

export async function getUserInfo(
  accessToken: string,
  gitlabUrl?: string,
): Promise<{
  id: number;
  username: string;
  name: string;
  email: string;
}> {
  const url = gitlabUrl ?? getConfig().gitlabUrl;
  const response = await fetch(`${url}/api/v4/user`, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });

  if (!response.ok) {
    throw new Error(`Failed to get user info: ${response.status}`);
  }

  return response.json();
}
