# Apigee X — Spec-Driven API Proxies

Contract-first Apigee X proxies. The OpenAPI spec is the **single source of truth**;
proxy bundles, policies, tests, and docs are derived from it.

## The golden rule (do not violate)

1. **Never hand-edit a generated proxy bundle** under `apiproxies/`. To change a proxy,
   change the **spec** (`specs/`) or the **template** (`templates/`) and re-render.
   A hook blocks manual edits to `apiproxies/`.
2. **Never put secrets in specs, bundles, or git.** Credentials live in Apigee KVMs /
   the secrets manager and are referenced by policy, never inlined.
3. **Generation is deterministic; you supply judgment.** Drive the tools (below) to
   produce the skeleton. Do not hand-author bundle XML from memory — you will drift
   from the spec and invent invalid policy attributes.

## Verified commands (pin these — verify with `--help` before trusting)

> Replace `<name>` with the API slug. Confirm exact flags/goals against your installed
> tool versions and record the working ones here. This block is the source of truth for
> commands; keep it accurate.

- **Lint spec:** `npx spectral lint specs/<name>.yaml --ruleset .spectral.yaml`
- **Render bundle:** `apigee-go-gen render apiproxy --template templates/proxy.yaml --set-oas spec=specs/<name>.yaml --output apiproxies/<name>`
- **Render local mock target:** `apigee-go-gen render apiproxy --template templates/mock.yaml --set-oas spec=specs/<name>.yaml --output .mocks/<name>`
- **Deploy to TEST env (Maven):** `mvn -P test -Dapigee.config.options=update install` then `mvn -P test apigee-enterprise:deploy`
- **Run acceptance tests (apickli):** `APICKLI_BASE_URL=$TEST_HOST npm test -- tests/<name>`
- **Detect drift:** `apigee-go-gen render apiproxy ... --output /tmp/<name> && diff -r apiproxies/<name> /tmp/<name>`

## Repo layout

- `specs/` — OpenAPI 3.x specs. **Source of truth.**
- `templates/` — apigee-go-gen YAML templates encoding org conventions (do not bypass).
- `apiproxies/` — generated bundles. **Generated, never hand-edited.**
- `tests/` — apickli `.feature` files + step definitions, one folder per API.
- `config/` — environment config consumed by the Maven config plugin.
- `.spectral.yaml` — the org OpenAPI ruleset (governance gate).
- `.claude/` — agent config (this file's siblings).

## Conventions

- Proxy name derives from `info.title` (slugified); base path from `servers`/`x-base-path`.
- Every proxy MUST have: API-key or OAuth verification, a Quota, a SpikeArrest, JSON/XML
  threat protection, a target SSL config, and a global FaultRule. The template provides
  defaults; confirm per-API.
- Environment differences (target URLs, quota limits) belong in `config/` per env —
  never branched into the bundle.

## Workflow (follow every time)

1. **Plan first.** For any non-trivial change, enter plan mode and use the
   `proxy-explorer` subagent to map the spec + existing conventions. Review the plan
   before generating anything.
2. **Generate** with the `scaffold-proxy` skill — it runs the full lint → render →
   policy → test → validate pipeline.
3. **Review** the result with the `policy-reviewer` subagent before deploy.
4. **Validate** against the mock or TEST env with apickli. Do not consider work done
   until tests pass.
5. On spec change, **re-render and diff** to surface drift; resolve in spec/template.
