# Apple Messages Bridge Hardening Matrix

This document is the durable baseline for bridge reliability work. It maps known failure classes to their current handling, the tests that should catch regressions, and the Codex platform capabilities that should be adopted or explicitly deferred.

## Failure Matrix

| Surface | Failure class | Current hardening | Remaining gap |
| --- | --- | --- | --- |
| Messages ingress | Messages DB rows arrive before attachments are readable | Attachment metadata records `exists`; very recent rows with missing attachment files are deferred without advancing the cursor, then retried until files appear or the defer window expires | Add live evidence from a real delayed Messages attachment row if it recurs |
| Messages ingress | Image/file classification drift | Focused tests cover prompt attachment preservation plus SQLite fixtures for attachment-only rows, multiple attachments, PDFs, unsupported files, existence flags, and `~/` path expansion | Add live evidence if Messages introduces new attachment metadata shapes |
| Codex app-server turns | Final answer never arrives | App-server tests reject non-final agent messages and surface no-final failures | Add live marked smoke test for a Messages-launched long turn |
| Codex app-server callbacks | Tool/user-input callback silently returns empty or cancel | The default backend can persist a pending callback, send a Messages prompt, route the next trusted reply back to JSON-RPC, and clear terminal state | Add a live installed-helper callback smoke with a real app-server callback |
| Capability delegation | User says "use Computer Use/Chrome/Browser" without `@` mention | Natural-language aliases now become structured plugin mentions; CLI and Messages smoke commands can launch marked Chrome, Browser, and Computer Use probes | Add trusted-chat live Messages runs for each blocker-or-success probe |
| Dynamic tools | MCP tool succeeds/fails with odd content | Tests cover forwarding and image/text result normalization | Expand contract matrix for missing fields, stalled calls, and non-MCP namespaces |
| Outbound text | AppleScript accepts send but delivery is unknown | Bridge verifies outgoing rows in `message.text` and `message.attributedBody`, records DB row/error/delivery evidence, and exposes retry eligibility | Add live smoke coverage in the installed helper path |
| Outbound attachments | Valid `BRIDGE_ATTACH` stripped or ignored by prompt heuristics | Valid bridge directives are now explicit transport handoffs | Add live marked image-attachment smoke test |
| Outbound attachments | Messages delivery row delayed or failed | Attachment sink returns DB evidence when available, preserves failed DB rows such as `error=25`, and records retry eligibility | Broaden fake sqlite coverage for delayed rows and SMS/iMessage differences |
| Media continuity | Follow-up says "that image" but Codex receives no source image | Recent inbound/outbound image refs are persisted and attached to image follow-up prompts when the file still exists | Add live inbound-image and generated-image editing probes |
| Active jobs | Helper restarts with stale active job | Dead job recovery notifies and clears; cancel now terminates known descendant processes as well as the root pid | Move all state mutation behind one owner/actor |
| State files | `state.json` is truncated or corrupt | JSON store backs up corrupt files and falls back to defaults instead of wedging startup; doctor reports corrupt-state backup paths when present | Add live evidence the next time a real corrupt-state recovery happens |
| Automations | Poll loop rereads all historical session JSONL | Bounded scan API skips delivered lower-bound sessions and has read-budget coverage | Persist scan watermarks if session-id ordering proves insufficient |
| Automations | Diagnostic prompt creates automation | Classifier regression tests cover known false positives | Broaden natural-language classifier matrix |
| LaunchAgents/runtime | Installed helper, runtime copy, and source drift | Doctor/status expose runtime facts, helper/broker loaded state, and provenance comparison across expected executable, LaunchAgent plist, and loaded launchd program | Add source-vs-installed build identity comparison if release metadata becomes available |
| Codex version drift | Bridge leaves new platform features unused | Capability adoption table below records current state | Recheck after each Codex CLI/app-server upgrade |

## Tests Added Or Strengthened

- App-server callbacks: `item/tool/requestUserInput` and `mcpServer/elicitation/request` have deterministic Messages-backed responder coverage.
- Natural-language capability mentions: `use Computer Use`, `use Chrome`, and `use Browser` become structured plugin mentions.
- Explicit attachment handoff: a valid `BRIDGE_ATTACH:` line sends the file even when the original prompt did not match attachment-request heuristics.
- Last outbound send evidence: bridge state and `/status` expose the latest text/attachment attempt, DB row, delivery state, and retry eligibility.
- Media continuity: previous-image follow-ups attach the latest usable chat image or ask for the source image instead of inventing a new one.
- Delayed inbound attachments: recent missing attachment files defer cursor advancement and are retried; stale missing files do not wedge the bridge forever.
- SQLite ingress fixtures: attachment-only rows, multi-attachment rows, image/PDF/unsupported classification, existence flags, and `~/` expansion are covered.
- Automation scan budget: repeated automation forwarding can avoid rereading delivered historical rollout files.
- Automation creation status: `/codex automations` can show in-flight creation state instead of only stale routes.
- State recovery: corrupted state JSON is backed up and defaulted.

## Live Smoke Tests

Use explicit markers in message text and filenames so live probes are searchable and safe to clean up.

- Text probe: send `BRIDGE_SMOKE_TEXT_<timestamp>` and verify an outgoing Messages row.
- Attachment probe: generate `bridge-smoke-attachment-<timestamp>.png`, send via `BRIDGE_ATTACH:`, and verify attachment evidence.
- Inbound image probe: send an image into the trusted chat and verify app-server input includes a `localImage` item.
- Capability probes: ask for marked Browser, Chrome, and Computer Use actions; require exact blocker text instead of fallback prose.
- Messages command probes: send `/codex smoke chrome`, `/codex smoke browser`, `/codex smoke computer-use`, `/codex smoke automation`, `/codex smoke callback`, and `/codex smoke inbound-image-check` from the trusted chat.

## Codex Changelog Adoption

Source of truth: <https://developers.openai.com/codex/changelog>

| Capability | Bridge status | Next action |
| --- | --- | --- |
| Goals in Codex CLI | Deferred | Evaluate only after app-server exposes a stable goal API suitable for Messages-launched work |
| CLI image viewing / app-server image fidelity | Partially adopted | Preserve local image inputs; add fidelity/detail options if app-server schema supports them in this runtime |
| Remote Computer Use / browser control / Chrome extension | Partially adopted | Structured mentions and capability status exist; add live probes and exact blocker reporting |
| App-server Unix socket transport | Deferred | Prefer stdio until process lifecycle issues are settled; reassess for long-lived helper stability |
| App-server lifecycle/tool events | Partially adopted | Progress and callback blocker events are consumed; expand diagnostics around lifecycle events |
| Plugin discovery and installed-plugin mention APIs | Partially adopted | Capability cache and structured mentions exist; refresh per turn or bounded TTL to avoid stale callability |
| Permission profiles | Deferred | Current bridge uses `approvalPolicy: never` and `danger-full-access`; design a safer trusted-sender profile before adopting |
| Thread pagination / sticky environments / remote thread store | Deferred | Current bridge only needs active-thread continuity; revisit if history/status grows beyond simple reads |
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
