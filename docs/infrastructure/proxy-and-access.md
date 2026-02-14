---
title: Proxy and Access
order: 60
---

# Proxy and Access

Remote access to on-premise clusters typically requires a SOCKS proxy or VPN
tunnel. This page covers common connectivity patterns.

## SOCKS Proxy

For clusters behind a campus network or firewall, use a SOCKS5 proxy through
an SSH tunnel to a bastion host:

```bash
# Start a SOCKS5 proxy via SSH
ssh -D 1080 -fN bastion.example.com

# Configure tools to use the proxy
export HTTPS_PROXY=socks5h://localhost:1080
```

Once the proxy is running, `kubectl`, `tofu`, and `curl` commands will route
through it automatically via the `HTTPS_PROXY` environment variable.

## Justfile Integration

The `proxy-up` recipe starts the proxy, and `bk` / `bcurl` wrappers route
commands through it:

```bash
just proxy-up         # Start SOCKS proxy
just bk get pods -A   # kubectl through proxy
just bcurl https://... # curl through proxy
```

## Tailscale

For clusters accessible via Tailscale, no proxy is needed — the cluster nodes
are directly reachable on the tailnet. Ensure the Tailscale client is running
and authenticated.

## See Also

- [Clusters and Environments](./clusters-and-environments.md) -- namespace layout
- [Quick Start](./quick-start.md) -- deployment walkthrough
