# Spec-Driven Apigee X with Claude Code — Production Playbook

A practitioner's guide to running the contract-first pipeline reliably with an agent.
Stack assumed: Apigee X, OpenAPI 3.x, apigee-go-gen + apigeecli, Apigee Maven deploy
plugin, apickli, Spectral.

---

## 1. Core principles

1. **The spec is the contract and the source of truth.** Every downstream artifact is
   generated from it or validated against it. If the proxy and the spec disagree, the
   spec wins and the proxy is regenerated.
2. **Separate deterministic generation from judgment.** Templates and codegen produce
   the skeleton (reproducible, reviewable, diffable). The agent supplies the decisions a
   template cannot make: which policies, what test scenarios, security posture. The
   agent should almost never be hand-writing bundle XML.
3. **Close the loop with executable validation.** apickli against a generated mock or a
   TEST deployment gives the agent real pass/fail feedback so it self-corrects on facts,
   not vibes. This is the single biggest driver of reliability.
4. **Everything in git, nothing manual.** Specs, templates, config, tests, and `.claude/`
   are version-controlled. Generated bundles are committed but treated as build output —
   never edited by hand.
5. **Human gates on irreversible steps.** The agent scaffolds, tests, and proposes;
   humans approve deploys beyond TEST.

## 2. The pipeline (inner loop)

```
spec lint (Spectral)
   -> render bundle (apigee-go-gen, shared template)
   -> layer judgment policies (agent)
   -> generate apickli tests from spec
   -> validate against mock / TEST deploy (Maven plugin)
   -> drift check (re-render + diff)
   -> policy-reviewer audit
   -> human-approved promotion
```

Keep the loop fast: prefer the local generated mock for iteration; reserve TEST
deployments for integration validation.

## 3. Claude Code setup that holds up in production

- **CLAUDE.md is short and always-true.** Commands, conventions, the golden rule. If a
  line wouldn't cause a mistake when removed, cut it — long files get ignored.
- **One skill owns the pipeline** (`scaffold-proxy`) so the workflow runs identically
  every time instead of being re-prompted.
- **Subagents keep context clean and add a second opinion**: a cheap read-only explorer
  for planning, a judgment-model read-only reviewer for security. Read-only agents get
  only `Read, Grep, Glob`.
- **Hooks enforce, they don't think.** Block manual bundle edits at write time (a
  category error worth stopping immediately); run the heavy lint/test gate at
  submit/deploy time so you don't break the agent's reasoning mid-edit.
- **Plan mode before generation.** Review the plan; cheap insurance against a confident
  wrong turn.
- **Pin tool versions** (apigee-go-gen, apigeecli, plugin, Spectral, apickli) and pin the
  commands in CLAUDE.md. Agents are sensitive to flag drift across versions.

## 4. Pitfalls and how to prevent them

| # | Pitfall | Why it bites in production | Prevention |
|---|---------|----------------------------|------------|
| 1 | Agent hand-authors or hand-edits bundle XML | Invents invalid policy attributes; silently drifts from the spec; not reproducible | Golden rule in CLAUDE.md + `guard-generated.sh` hook blocking edits to `apiproxies/`; route all changes through spec/template |
| 2 | Spec and deployed proxy drift over time | Docs say one thing, runtime does another; consumers break | Re-render + `diff` on every change; treat any diff as a defect; never patch the bundle directly |
| 3 | Secrets inlined in spec, bundle, or git | Credential leak; fails audit; rotation impossible | KVM / secrets manager only; policy-reviewer treats literal secrets as CRITICAL; secret-scanning in CI |
| 4 | Environment values baked into the bundle | Can't promote the same artifact across envs; risky copy-paste between environments | Externalize to `config/` per env via the Maven config plugin; one bundle, many env configs |
| 5 | "Generated, therefore correct" complacency | Codegen omits auth/quota or picks weak defaults; ships insecure | Mandatory `policy-reviewer` audit before deploy; policy baseline encoded in the template |
| 6 | Weak or absent tests; happy-path only | Regressions slip through; spec changes silently break consumers | Generate auth-failure, schema-validation, quota, and negative cases per operation; tests must pass before "done" |
| 7 | Flaky/order-dependent apickli tests | Pipeline noise erodes trust; real failures ignored | Isolate state per scenario; use the generated mock for deterministic runs; no shared mutable fixtures |
| 8 | Agent context bloat on large specs | Attention degrades, quality drops, auto-compaction loses the thread | Delegate exploration to the `proxy-explorer` subagent; keep the main session focused on decisions |
| 9 | Non-determinism between runs | Two runs produce different bundles; reviews become meaningless | Keep judgment in the template/spec (deterministic), not in free-form per-run prompts; diff to confirm stability |
| 10 | Over-broad agent permissions / auto-deploy | An agent push to a shared/prod env is hard to undo | Read-only reviewers; deploys human-gated; least-privilege service accounts; never let the agent enter credentials or change access controls |
| 11 | Revision/rollback not planned | A bad deploy with no fast undo | Use Apigee revisions; keep prior revision deployable; script rollback; deploy via Maven profiles per env |
| 12 | Template becomes a dumping ground | Unreviewable, every API inherits cruft | Treat the template as code: review template changes harder than proxy changes; keep it minimal and documented |
| 13 | Tool/flag drift breaks the pipeline silently | Commands in CLAUDE.md stop matching installed versions | Pin versions; CI runs the exact CLAUDE.md commands so drift fails loudly |
| 14 | CI/CD and the agent loop diverge | Works locally, fails in pipeline (or vice versa) | CI runs the same skill commands (lint -> render -> diff -> test); the agent loop mirrors CI exactly |

## 5. Production readiness checklist

- [ ] Spectral ruleset encodes org API governance and runs as the first gate.
- [ ] Shared template provides the security/resilience baseline; reviewed as code.
- [ ] Generated bundles committed but write-protected from manual edits (hook).
- [ ] apickli suite covers happy path + auth + schema + negative cases per operation.
- [ ] Local mock loop for fast iteration; TEST deploy for integration validation.
- [ ] Secrets in KVM/secrets manager; secret-scanning in CI; zero literals in repo.
- [ ] Env config externalized per environment; one artifact promoted across envs.
- [ ] Deploys human-gated beyond TEST; rollback to prior revision scripted and tested.
- [ ] Tool versions pinned; CI runs the same commands as the agent.
- [ ] policy-reviewer audit required before any deploy.

## 6. Notes on tooling currency

- apigee-go-gen (the YAML + Go-template generator for OpenAPI/GraphQL/gRPC, with mock
  generation) is the current Google/Apigee approach for templated proxy generation;
  apigeecli also has built-in OpenAPI-to-proxy generation and handles deploy on X/hybrid.
- Consider Apigee API hub for spec registry/versioning if you want a managed catalog of
  specs the pipeline reads from.
- Verify every command's exact flags against your installed versions — flags evolve, and
  CLAUDE.md should hold only commands you've confirmed work.
