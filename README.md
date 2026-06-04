# Spec-Driven Apigee X — Interactive Guide

A single-page, blueprint-styled visualization of **contract-first Apigee X proxy
development with Claude Code**. The OpenAPI spec is the single source of truth; the
proxy bundle, policies, tests, and docs are all generated from it or validated against it.

The site walks the full inner loop — **lint → render → policies → tests → validate →
drift check → review → promote** — through a real-world use case (**Meridian Bank's
Open Banking Accounts API**), and ships a **Starter Kit**: complete, copy-paste-ready
files plus a one-shot `bootstrap.sh` that scaffolds the entire repo.

> The page is **not a demo** — every code block is a real, runnable file. Copy a single
> file, download it, or grab the bootstrap script that writes the whole directory tree.

## View it

The site lives in [`docs/index.html`](docs/index.html) — a fully self-contained file
(no build step, no dependencies). Open it locally:

```bash
open docs/index.html          # macOS
# or serve it:
python3 -m http.server -d docs 8080   # then visit http://localhost:8080
```

## Publish to GitHub Pages

Two supported paths — pick one.

### Option A — GitHub Actions (recommended, auto-deploys on every push)

A workflow is already included at [`.github/workflows/deploy-pages.yml`](.github/workflows/deploy-pages.yml).
It uploads the `docs/` folder as the Pages artifact and deploys it.

```bash
# 1. create the repo on GitHub (using the gh CLI), then push
gh repo create <your-org>/spec-driven-apigee --public --source=. --remote=origin --push

# 2. enable Pages with the GitHub Actions source (one-time)
gh api -X POST repos/<your-org>/spec-driven-apigee/pages -f build_type=workflow
```

On the next push to `main`, the Action publishes the site. Its URL appears under the
repo's **Actions → Deploy GitHub Pages** run and in **Settings → Pages**.

### Option B — Settings → Pages, serve from `/docs` (no Actions)

```bash
git remote add origin https://github.com/<your-org>/spec-driven-apigee.git
git push -u origin main
```

Then in the repo: **Settings → Pages → Build and deployment → Source: _Deploy from a
branch_ → Branch: `main` / folder: `/docs`**. The `docs/.nojekyll` file is already in
place so the static HTML is served verbatim.

The published URL is `https://<your-org>.github.io/spec-driven-apigee/`.

## What's in the Starter Kit (inside the page)

| File | Role |
|------|------|
| `specs/accounts.yaml` | The OpenAPI contract — **source of truth**, no secrets |
| `.spectral.yaml` | Org governance ruleset — the first gate |
| `templates/proxy.yaml` | apigee-go-gen template holding the security baseline |
| `Makefile` | Pipeline targets; CI runs the same ones as the agent |
| `config/test.properties` | Per-env values for the Maven config plugin |
| `tests/accounts/features/accounts.feature` | apickli suite (auth / schema / quota / faults) |
| `CLAUDE.md` | Always-true agent context — the golden rule |
| `.claude/settings.json` | Wires the enforcement hooks |
| `.claude/skills/scaffold-proxy/SKILL.md` | One skill owns the whole pipeline |
| `.claude/agents/proxy-explorer.md` | Read-only planner (haiku) |
| `.claude/agents/policy-reviewer.md` | Read-only security auditor (sonnet) |
| `.claude/hooks/guard-generated.sh` | Blocks hand-edits to generated bundles |
| `.claude/hooks/deploy-gate.sh` | Re-lints on any deploy command |

## Repo layout

```
docs/index.html        # the interactive site (self-contained)
docs/.nojekyll         # serve static HTML verbatim on Pages
.github/workflows/     # auto-deploy to GitHub Pages
CLAUDE.md              # agent project instructions (the golden rule)
SPEC_DRIVEN_PLAYBOOK.md, SKILL.md, *.md, *.sh   # the source artifacts the site is built from
```

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)
