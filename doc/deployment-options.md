# Deployment Infrastructure Options

This app is a monolithic Rails 8 app: one web process, PostgreSQL (3 logical databases for primary/cache/queue), Solid Queue running in-process via Puma, and Solid Cache. No Redis. No separate worker process. All configuration for Docker + Kamal is already in place (`Dockerfile`, `config/deploy.yml`).

---

## Free-tier options

### Option 1 — Oracle Cloud Always Free (recommended)

Oracle's Always Free tier is the most generous genuinely-free cloud offering. It does not expire.

**What you get:**
- 1× ARM VM: up to 4 OCPUs, 24 GB RAM, 200 GB block storage
- *Or* 2× AMD VMs: 1 OCPU, 1 GB RAM each (less headroom)
- Outbound bandwidth: 10 TB/month

**Architecture:** Self-host PostgreSQL on the same ARM VM alongside the Rails app. Use Kamal to deploy (already configured — just swap in the real server IP and a Docker registry).

**Docker registry:** GitHub Container Registry (GHCR) is free for public images and $0 for private images up to package storage limits. Set `image: ghcr.io/<username>/community_bookshelf` in `config/deploy.yml`.

**SSL:** Kamal's built-in proxy handles Let's Encrypt automatically.

**Cost:** $0 forever (Oracle commits to Always Free resources not being taken away).

**Tradeoffs:**
- You manage the OS (updates, firewall, SSH keys)
- Postgres backups are your responsibility (pg_dump cron job or Kamal hook)
- Oracle's sign-up requires a credit card for identity verification, but Always Free resources are never charged
- ARM VMs require confirming Docker images build for `linux/arm64` (the existing Dockerfile does)

**What to change in `config/deploy.yml`:**
```yaml
image: ghcr.io/<your-github-username>/community_bookshelf

servers:
  web:
    - <your-oracle-vm-ip>

registry:
  server: ghcr.io
  username: <your-github-username>
  password:
    - KAMAL_REGISTRY_PASSWORD   # GitHub personal access token
```

---

### Option 2 — Render (free web tier) + Neon (free Postgres)

Fully managed, no Linux administration. The tradeoff is that Render's free web tier **spins down after 15 minutes of inactivity**, causing a 30–60 second cold start on the next request.

**Render (web service):**
- Free tier: 512 MB RAM, 0.1 CPU, auto-deploy from GitHub
- Accepts the existing `Dockerfile` directly (set runtime to Docker)
- SSL, health checks, and deploy previews included

**Neon (Postgres):**
- Free tier: 0.5 GB storage, serverless Postgres, always available (does not sleep)
- Provides a single `DATABASE_URL` — configure all three Rails databases to use it (or accept that cache and queue share the primary connection string; Solid Cache and Solid Queue work fine with a shared database in this tier)

**Cost:** $0 (suitable for demos, staging, or very low-traffic use; not ideal if cold starts are unacceptable)

**What changes:**
- No Kamal; deploy via Render's GitHub integration
- Set `DATABASE_URL` in Render's environment variables panel
- Set `RAILS_MASTER_KEY` and `RAILS_ENV=production` in Render env vars

---

### Option 3 — Fly.io (limited free allowances)

Fly.io is Docker-native and works with the existing `Dockerfile`. Their free allowances include shared VMs, though Postgres is no longer free.

**Free tier:** 3× `shared-cpu-1x` VMs with 256 MB RAM. Rails with eager loading typically needs 300–512 MB, so this tier is tight. A single `shared-cpu-1x-512mb` machine costs ~$3.83/month.

**Postgres:** No longer free on Fly. Pair with Neon's free tier (via `DATABASE_URL`) instead.

**Verdict:** Viable if you're comfortable with the memory constraint; pairs well with Neon for the database. Better DX than Oracle Cloud but no longer fully free for real workloads.

---

## Comparison

| Option | Cost | Cold starts | Ops burden | Uses existing Kamal config |
|---|---|---|---|---|
| Oracle Cloud + Kamal | $0 | None | Moderate (OS mgmt) | Yes |
| Render + Neon | $0 | Yes (15 min idle) | Low | No |
| Fly.io + Neon | ~$0–4/mo | None | Low | No (use `flyctl`) |

---

## When cost is no longer a constraint

The app is already optimized for single-server deployment. When ready to pay:

| Budget | Recommendation |
|---|---|
| ~$6/mo | Hetzner CX22 VPS (2 vCPU, 4 GB RAM) + Kamal + self-hosted Postgres |
| ~$15/mo | Hetzner VPS + managed Postgres (Supabase Pro or Neon paid) |
| ~$10–15/mo | Railway Hobby plan (Postgres included, zero ops) |
| ~$15–20/mo | Fly.io (2× `shared-cpu-1x-512mb`) + Fly Postgres |
