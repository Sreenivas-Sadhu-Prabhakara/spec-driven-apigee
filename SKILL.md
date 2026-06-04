---
name: scaffold-proxy
description: >
  Generate or update an Apigee X proxy from an OpenAPI spec. Use whenever the user
  wants to scaffold a new proxy, regenerate one after a spec change, add policies, or
  produce apickli tests for an API. Runs the full contract-first pipeline:
  lint -> render -> policies -> tests -> validate.
---

# Scaffold an Apigee X proxy from a spec

You are executing the contract-first pipeline. The OpenAPI spec is the source of truth.
Drive the deterministic tools; do not hand-author bundle XML. Read `CLAUDE.md` for the
verified commands and conventions before running anything.

## Inputs
- `<name>`: API slug. If not given, infer from the spec filename in `specs/`.
- Confirm the spec path exists before proceeding. If multiple specs match, ask which.

## Steps (do them in order; stop and report on any failure)

1. **Lint the spec first.** Run the Spectral command from CLAUDE.md. If it fails,
   STOP and surface the violations — do not generate from an invalid contract.

2. **Render the bundle deterministically.** Run the `apigee-go-gen render apiproxy`
   command into `apiproxies/<name>`. Use the shared template in `templates/`; do not
   write bundle XML yourself. If the template lacks something the spec needs, propose a
   **template** change, not a one-off bundle edit.

3. **Layer judgment policies.** This is the part templates can't decide. Confirm the
   proxy has, appropriate to this API: key/OAuth verification, Quota, SpikeArrest,
   threat protection, target SSL, and a global FaultRule. Express any additions through
   the template or a spec extension (`x-` fields) so they're reproducible — never as a
   manual edit to the generated bundle.

4. **Generate apickli tests.** For each operation in the spec, create/refresh a Gherkin
   `.feature` in `tests/<name>/features/` covering: happy path, auth-missing (401/403),
   quota/rate behavior where testable, schema validation of the response, and at least
   one negative/edge case per operation. Wire step definitions to apickli. Keep
   assertions tied to the spec's response schemas.

5. **Validate locally, then on TEST.** Render the local mock target and point apickli at
   it for a fast loop, or deploy to TEST via the Maven command and run apickli there.
   Read failures and self-correct by fixing the **spec or template**, then re-running
   from step 1. Do not mark complete until tests pass.

6. **Drift check.** Re-render to a temp dir and diff against `apiproxies/<name>`. Report
   any diff as drift to be resolved in the spec/template.

## Before handing off
- Hand the result to the `policy-reviewer` subagent for a security/governance audit.
- Summarize: what changed, test results, any open template gaps. Do NOT deploy to
  non-TEST environments — that's a human-gated step.
