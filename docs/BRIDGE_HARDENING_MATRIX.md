# Apple Messages Bridge Hardening Matrix

This document is the durable baseline for bridge reliability work. It maps known failure classes to their current handling, the tests that should catch regressions, and the Codex platform capabilities that should be adopted or explicitly deferred.

## Failure Matrix

| Surface | Failure class | Current hardening | Remaining gap |
| --- | --- | --- | --- |
| Messages ingress | Messages DB rows arrive before attachments are readable | Attachment metadata records `exists`; very recent rows with missing attachment files are deferred without advancing the cursor, then retried until files appear or the defer window expires | Add live evidence from a real delayed Messages attachment row if it recurs |
| Messages ingress | Image/file classification drift | Focused tests cover prompt attachment preservation plus SQLite fixtures for attachment-only rows, multiple attachments, PDFs, unsupported files, existence flags, and `~/` path expansion | Add live evidence if Messages introduces new attachment metadata shapes |
| Codex app-server turns | Final answer never arrives | App-server tests reject non-final agent messages, surface no-final failures, and `/codex smoke app-server` / CLI smoke can run a marked final-answer probe | Add trusted-chat evidence for `/codex smoke app-server` |
| Codex app-server callbacks | Tool/user-input callback silently returns empty or cancel | The default backend can persist a pending callback, send a Messages prompt, route the next trusted reply back to JSON-RPC, clear terminal state, and launch `/codex smoke app-server-callback` from Messages | Add trusted-chat evidence for `/codex smoke app-server-callback` |
| Capability delegation | User says "use Computer Use/Chrome/Browser" without `@` mention | Natural-language aliases now become structured plugin mentions; CLI and Messages smoke commands can launch marked Chrome, Browser, and Computer Use probes; `cgWindowNotFound` diagnostics include AX/frontmost/window counts and explain all-zero-window preflight results | Add trusted-chat live Messages runs for each blocker-or-success probe |
| Dynamic tools | MCP tool succeeds/fails with odd content | Tests cover forwarding, unsupported non-MCP namespaces, malformed request fields, stalled MCP calls, MCP `isError`, image/text/primitive/unknown object normalization, and searchable object keys | Add live evidence from a real plugin/tool stall if it recurs |
| Outbound text | AppleScript accepts send but delivery is unknown | Bridge verifies outgoing rows in `message.text` and `message.attributedBody`, records DB row/error/delivery evidence, exposes retry eligibility, has live CLI smoke evidence, and can observe trusted-chat command/reply rows | Add `/codex smoke text` evidence from the trusted Messages chat |
| Outbound attachments | Valid `BRIDGE_ATTACH` stripped or ignored by prompt heuristics | Valid bridge directives are now explicit transport handoffs with live marked image-attachment and bridge-attach smoke evidence, `/codex smoke generated-image` can exercise app-server-produced media, and trusted-gate evidence can surface missing or failed trusted-chat replies | Add `/codex smoke attachment`, `/codex smoke bridge-attach`, and `/codex smoke generated-image` evidence from the trusted Messages chat |
| Outbound attachments | Messages delivery row delayed or failed | Attachment sink returns DB evidence when available, preserves failed DB rows such as `error=25`, records retry eligibility, and has fake-runtime coverage for delayed rows plus SMS service selection | Add live evidence if SMS-specific attachment behavior diverges from iMessage |
| Media continuity | Follow-up says "that image" but Codex receives no source image | Recent inbound/outbound image refs are persisted and attached to image follow-up prompts when the file still exists and is app-server-compatible; status marks unsupported image refs; outbound-image smoke verifies a sent image can be reused as app-server image input; edit-image smoke verifies the source image is reused, edited into a new artifact, and delivered; media final replies send attachments before success text | Add trusted-chat generated-image and edit-image evidence |
| Active jobs | Helper restarts or stale saves lose active-job provenance | Dead job recovery notifies and clears; cancel now terminates known descendant processes as well as the root pid; same-job saves merge process/thread/turn/output metadata; active-job, callback, cancel, outbound-send, cursor, media, pending-batch, prompt job-start, session lifecycle, and automation updates go through `BridgeStateBox` mutation helpers; transient prompt/command/callback dispatch goes through `BridgeJobQueue` | Prove remaining live trusted-chat callback/media flows and runtime process diagnostics |
| State files | `state.json` is truncated, corrupt, or stale saves clobber bridge evidence | JSON store backs up corrupt files, falls back to defaults, serializes same-path writes across store instances, preserves concurrent automation/media/callback/outbound-send fields, and doctor reports corrupt-state backup paths when present; `BridgeStateBox` has concurrent mutation coverage and source-level regression coverage for session/job-start mutation paths | Add live evidence the next time a real corrupt-state recovery happens |
| Automations | Poll loop rereads all historical session JSONL | Bounded scan API skips delivered lower-bound sessions and has read-budget coverage | Persist scan watermarks if session-id ordering proves insufficient |
| Automations | Diagnostic prompt creates automation | Classifier regression tests cover management/debug/list/status false positives, schedule/calendar false positives, and reminder/monitor/follow-up positives | Keep expanding phrase fixtures from live trusted-chat misses |
| LaunchAgents/runtime | Installed helper, runtime copy, and source drift | Doctor/status expose runtime facts, helper/broker loaded state, provenance comparison across expected executable, LaunchAgent plist, loaded launchd program, and built-vs-installed executable identity | Add release/build metadata checks when packaged artifacts expose stable build ids |
| Codex version drift | Bridge leaves new platform features unused | Capability adoption table below records current state; status/doctor mark capability caches stale after 24h | Recheck after each Codex CLI/app-server upgrade |

## Tests Added Or Strengthened

- App-server callbacks: `item/tool/requestUserInput` and `mcpServer/elicitation/request` have deterministic Messages-backed responder coverage; `codexmsgctl-swift smoke app-server-callback` now probes the real app-server path and reports the current live blocker when Codex does not emit a callback request.
- App-server final answers: app-server smoke commands verify a normal marked turn returns a final reply with thread/turn evidence.
- App-server server requests: current approval request methods are answered with safe declines and unsupported client-only request methods return visible JSON-RPC errors, preventing unhandled app-server requests from becoming silent waits.
- Dynamic app-server tools: MCP forwarding now has contract coverage for unsupported namespaces, malformed requests, stalled MCP calls, error responses, images, primitives, and unknown JSON object content.
- Natural-language capability mentions: `use Computer Use`, `use Chrome`, and `use Browser` become structured plugin mentions.
- Explicit attachment handoff: a valid `BRIDGE_ATTACH:` line sends the file even when the original prompt did not match attachment-request heuristics.
- BRIDGE_ATTACH smoke: marked bridge-attach smoke verifies directive parsing, attachment-first delivery, and Messages DB evidence before success text; generated-image and edit-image smokes ask a real app-server turn to create or edit and attach the artifact from both CLI and Messages command surfaces.
- Last outbound send evidence: bridge state and `/status` expose the latest text/attachment attempt, DB row, delivery state, and retry eligibility.
- Outbound attachment verification: fake-runtime tests cover delayed Messages DB rows, failed attachment rows, clipboard retry, and SMS service selection.
- Media continuity: previous-image follow-ups attach the latest app-server-compatible chat image or ask for the source image instead of inventing a new one.
- Media delivery truth: `BRIDGE_ATTACH:` final replies send the file before success text, and failed attachment delivery blocks the success text.
- Outbound media continuity: marked outbound-image smoke sends an image, records the recent outbound media ref, then verifies a "that image" app-server request carries the exact file as image input.
- Delayed inbound attachments: recent missing attachment files defer cursor advancement and are retried; stale missing files do not wedge the bridge forever.
- SQLite ingress fixtures: attachment-only rows, multi-attachment rows, image/PDF/unsupported classification, existence flags, and `~/` expansion are covered.
- Automation scan budget: repeated automation forwarding can avoid rereading delivered historical rollout files.
- Automation creation status: `/codex automations` can show in-flight creation state instead of only stale routes.
- State recovery: corrupted state JSON is backed up and defaulted.
- State merge safety: stale saves preserve automation routes/status, recent media refs, pending callbacks, outbound delivery evidence, and same-active-job runtime metadata; path-scoped store locking covers independent store instances writing the same `state.json`; `BridgeStateBox` serializes in-memory service mutations for cursor, media, outbound, pending-batch, callback, cancel, active-job, prompt job-start, Codex session lifecycle, and automation paths; `BridgeJobQueue` owns transient prompt, local-command, and callback-reply dispatch ordering.
- Capability drift: status and doctor expose stale capability caches after 24h instead of showing only an unqualified timestamp.
- Gate harness: `codexmsgctl-swift gates` enumerates deterministic local gates, explicit live CLI smoke commands, trusted Messages commands, current readiness, and the remaining proof gaps.
- Trusted gate observer: `codexmsgctl-swift trusted-gates` and `/codex trusted-gates` read Messages DB evidence for each trusted `/codex ...` gate command and report missing inbound rows, missing outbound replies, outbound `message.error` values, attributed-body snippets, and the next missing command to send. Two-step callback smokes also report whether they are awaiting the trusted follow-up reply or the final completion reply, so an initial prompt cannot masquerade as an observed gate.

## Live Smoke Tests

Use explicit markers in message text and filenames so live probes are searchable and safe to clean up.

- Text probe: send `BRIDGE_SMOKE_TEXT_<timestamp>` and verify an outgoing Messages row.
- Attachment probe: generate `bridge-smoke-attachment-<timestamp>.png`, send via `BRIDGE_ATTACH:`, and verify attachment evidence; use `codexmsgctl-swift smoke bridge-attach` for the final-reply directive path.
- Inbound image probe: send an image into the trusted chat and verify app-server input includes a `localImage` item.
- Capability probes: ask for marked Browser, Chrome, and Computer Use actions; require exact blocker text instead of fallback prose.
- Live smoke provenance: CLI smoke results and `doctor --probe-computer-use` persist the latest marker/status/detail by smoke name into bridge state, and status/doctor show that evidence next to capability inventory so callable/discovered inventory cannot hide a real runtime blocker.
- Messages command probes: send `/codex smoke app-server`, `/codex smoke app-server-callback`, `/codex smoke generated-image`, `/codex smoke chrome`, `/codex smoke browser`, `/codex smoke computer-use`, `/codex smoke automation`, `/codex smoke callback`, `/codex smoke bridge-attach`, `/codex smoke inbound-image-check`, and `/codex smoke outbound-image-check` from the trusted chat.

## Codex Changelog Adoption

Source of truth: <https://developers.openai.com/codex/changelog>

Last refreshed: 2026-05-22 against installed Codex CLI 0.133.0 and installed app 0.3.2/bridge runtime. The official changelog currently includes May 2026 app-server thread pagination, stdio exec-server transport, environment-provider work, Chrome extension updates, remote-control/app-server API changes, plugin discovery/share changes, and permission-profile metadata.

| Capability | Bridge status | Next action |
| --- | --- | --- |
| Goals in Codex CLI | Deferred | Evaluate only after app-server exposes a stable goal API suitable for Messages-launched work |
| CLI image viewing / app-server image fidelity | Adopted for current bridge scope | Local image inputs are preserved, generated media and edit-image smokes verify app-server can create/read PNG artifacts, and unsupported image refs are skipped or converted before app-server use |
| Remote Computer Use / browser control / Chrome extension | Partially adopted | Structured mentions, CLI/Messages smokes, capability cache, and exact blocker reporting exist; trusted-chat live evidence remains required for each blocker-or-success probe |
| App-server Unix socket transport | Deferred | The bridge still uses `codex app-server --listen stdio://`; prefer stdio until process lifecycle and callback gates are fully proven, then reassess Unix sockets for daemon stability |
| Stdio exec-server transport | No bridge action needed | The bridge does not own Codex command execution transport; continue verifying app-server command/progress events and child cleanup |
| App-server lifecycle/tool events | Adopted for current bridge scope | Session/turn/progress/blocker/question events are consumed in status, smoke output, and active-job provenance; keep extending diagnostics from live failures |
| Plugin discovery and installed-plugin mention APIs | Adopted for current bridge scope | Capability cache records skills/plugins/apps/MCP inventory; natural-language Chrome/Browser/Computer Use aliases become structured mentions; stale cache age is visible in status/doctor |
| Plugin share/discoverability updates | Deferred | Relevant to plugin management UI, not bridge transport; revisit if Messages adds plugin install/share commands |
| Permission profiles / active profile metadata | Deferred | Current bridge intentionally uses a permissive trusted-Mac profile; design a safer trusted-sender profile before adopting app-server permission-profile switching |
| Thread pagination / sticky environments / environment providers | Deferred | Current bridge only needs active-thread continuity and simple thread reads; revisit if `/codex history` or status grows beyond bounded recent-thread reads |
| Remote thread store | Deferred | Official changelog indicates remote thread-store implementation churn/removal; keep bridge state local until current app-server API stabilizes |
| OpenAPI MCP and connector elicitations | Partially adopted | Dynamic MCP forwarding and deterministic elicitation handling exist; live installed-helper elicitation smoke remains the main parity gap |

## Acceptance Baseline

Before claiming bridge reliability work is complete, run:

- `swift run BridgeCoreTests`
- `swift run BridgeCoreSelfTest`
- `swift test`
- `swift run codexmsgctl-swift doctor --probe-computer-use`
- `swift run codexmsgctl-swift smoke text`
- `swift run codexmsgctl-swift smoke attachment`
- `/codex status` from the trusted Messages chat
- One marked live text probe
- One marked live attachment probe
- One marked live capability probe for Browser/Chrome/Computer Use
