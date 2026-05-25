# E2B sandbox template

The agent sandboxes (E2B `provision`/`execute` tools) run on an E2B template.
This is its source so it lives in version control instead of only on someone's
laptop.

`E2B_TEMPLATE` (see `src/server/env.ts`) selects which template the platform
uses when it spins up a sandbox.

## What's in it
- Base: `e2bdev/code-interpreter` (Python + Node + Jupyter).
- **Pre-cloned repos** (no per-session clone):
  - `https://github.com/BerriAI/litellm` → `/home/user/litellm`
  - `https://github.com/BerriAI/litellm-docs` → `/home/user/litellm-docs`
- **All `litellm[proxy]` deps pre-installed** — no per-session install wait.
- **Global pip.conf** always points at `https://pypi.org/simple` with the combined CA cert — no `--trusted-host` / `--index-url` flags ever needed.
- **`uv` pre-installed** via pip (not the curl/astral installer) so `uv_build` resolves cleanly.
- **PostgreSQL cluster** owned by `user` at `/home/user/pgdata`, dev db `litellm` pre-created.
- **`/usr/local/bin/dev-up`**: one command to start the proxy stack.

Both repos are public, so no token is baked into the image.

## Standing up the proxy (from inside a sandbox)

```bash
# Start postgres + export env vars into your shell
source /usr/local/bin/dev-up

# Run the proxy
cd ~/litellm && python -m litellm.proxy.proxy_cli --port 4000 --detailed_debug
```

Dev credentials baked into `dev-up`:

| Var | Value |
|-----|-------|
| `DATABASE_URL` | `postgresql://litellm:litellm@localhost:5432/litellm` |
| `LITELLM_MASTER_KEY` | `sk-1234` |
| `LITELLM_SALT_KEY` | `sk-litellm-salt-dev-unsafe` |
| `STORE_MODEL_IN_DB` | `True` |

## Build / update
Requires E2B CLI auth (`e2b auth login`) for the team that owns the template.

```bash
cd e2b
e2b template build --name litellm-4gb --cpu-count 8 --memory-mb 4096
```

`--cpu-count 8 --memory-mb 4096` matches the 4 GB spec. After it builds, set
`E2B_TEMPLATE` (and `E2B_API_KEY` for the owning team) on the platform service.

To refresh the pinned repo contents, rebuild with `--no-cache`.
```
