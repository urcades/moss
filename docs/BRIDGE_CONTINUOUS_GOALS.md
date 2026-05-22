# Apple Messages Bridge Continuous Goals

This is the working contract for continuing bridge hardening until every gate in `BRIDGE_GATE_GOALS.md` is proven. A goal is complete only when deterministic tests, live smoke evidence, installed-helper behavior, and status/doctor output agree.

## Goal A: Local Gate Harness

Success: one command can run or clearly enumerate every non-destructive local gate, including `BridgeCoreTests`, `BridgeCoreSelfTest`, `swift test`, `doctor --probe-computer-use`, and CLI smoke probes.

Evidence:
- Command output shows pass/fail for each local gate with marker ids, row ids, thread ids, turn ids, or blocker text where applicable.
- Gate docs record the latest live evidence.

Current status: in progress. Individual commands exist, `codexmsgctl-swift gates` prints the complete deterministic, live CLI, and trusted Messages gate checklist with current readiness hints, `/codex gates` exposes the same checklist from Apple Messages, and `/codex trusted-gates` exposes trusted inbound/outbound row evidence from Apple Messages.

## Goal B: Trusted Messages Gate Harness

Success: trusted-chat commands can prove `/codex status` and every `/codex smoke ...` surface from Apple Messages, and the CLI can summarize the required inbound command, observed inbound row, outbound reply row, marker, and delivery evidence.

Evidence:
- `/codex status` from the trusted chat agrees with `codexmsgctl-swift status`.
- Trusted-chat `/codex smoke app-server`, `app-server-callback`, `mcp-elicitation-callback`, `generated-image`, `edit-image-check`, `text`, `attachment`, `automation`, `callback`, `inbound-image-check`, `outbound-image-check`, `chrome`, `browser`, and `computer-use` have observed inbound rows and outgoing reply evidence.
- `codexmsgctl-swift trusted-gates` reports each trusted command as `observed`, `missing-inbound`, `missing-outbound`, `outbound-error-*`, `awaiting-followup`, or `awaiting-completion` from Messages DB evidence.

Current status: in progress and partly externally gated, because true trusted inbound rows must come from Apple Messages rather than this process sending `is_from_me=1` rows. `codexmsgctl-swift trusted-gates` and `/codex trusted-gates` now observe real inbound/outbound row evidence without sending messages, and two-step callback gates remain pending until the trusted follow-up reply and final completion reply are both visible.

## Goal C: Real Callback Parity

Success: a real app-server-generated `item/tool/requestUserInput` or `mcpServer/elicitation/request` pauses through the installed helper, sends the prompt to Messages, captures the next trusted reply, returns the JSON-RPC response, and completes the original turn.

Evidence:
- Fake-runtime callback tests pass.
- `/codex smoke app-server-callback` starts a real app-server callback turn from Messages and expects the next trusted reply to complete that original turn.
- `/codex smoke mcp-elicitation-callback` starts a real app-server MCP elicitation turn from Messages and expects the next trusted reply to complete that original turn.
- `codexmsgctl-swift smoke app-server-callback` starts a real app-server callback turn locally with an automatic responder; on 2026-05-22 it failed before bridge callback handling because Codex returned `BLOCKED request_user_input is unavailable in Default mode` without emitting a callback request.
- `codexmsgctl-swift smoke mcp-elicitation-callback` starts a separate real app-server MCP elicitation prompt locally with the same automatic responder and records its live blocker independently.
- A live installed-helper smoke records callback id, inbound prompt row, trusted reply row/guid, app-server thread/turn id, and final answer.

Current status: deterministic support exists and the CLI/trusted-chat commands exist; live real-callback proof is blocked by Codex runtime mode/callback availability, not by the bridge responder seam.

## Goal D: Media Delivery And Editing Truth

Success: generated media and follow-up edits never claim success unless a validated attachment send happened, and follow-up prompts reuse the correct recent inbound or outbound image.

Evidence:
- CLI and Messages smoke can prove inbound-image and outbound-image continuity with local image inputs.
- A live generated-image `BRIDGE_ATTACH:` flow records delivery row/error/transfer state.
- A live edit follow-up uses the previous real image or asks for the source.

Current status: inbound/outbound continuity smoke exists, `BRIDGE_ATTACH:` final replies now send attachments before success text, `codexmsgctl-swift smoke bridge-attach` verifies the directive handoff with Messages DB evidence, `codexmsgctl-swift smoke generated-image` asks a real app-server turn to create and attach a marked PNG, `codexmsgctl-swift smoke edit-image-check` asks a real app-server turn to edit the latest chat image and attach the result, and `/codex smoke generated-image` plus `/codex smoke edit-image-check` expose those generated-media gates from Messages. Live trusted-chat generated-image and edit probes remain.

## Goal E: State Owner And Process Supervision

Success: state mutation is single-owner or versioned enough that simultaneous tick, callback, cancel, send-record, automation, and CLI writes cannot clobber unrelated fields; timeout/cancel leaves no bridge-owned process descendants.

Evidence:
- Concurrency tests cover separate store instances and simultaneous service mutations.
- Doctor reports app-server process groups and orphan checks.
- Timeout/cancel tests verify process-tree cleanup.

Current status: field merge and path-scoped state write locking exist, and `BridgeService` now stores its in-memory state behind a serialized `BridgeStateBox` with deterministic concurrent-mutation coverage. Cursor updates, outbound send evidence, media refs, pending batch state, interactive callback reply/expiry/clear, active-job updates, callback completion, cancel transitions, prompt job-start, Codex session lifecycle updates, automation creation status, automation route persistence, and automation delivery cursors now use serialized mutation helpers. Transient prompt, command, and callback dispatch now flows through `BridgeJobQueue`, with source-level regression coverage preventing raw queue mutation from creeping back into `BridgeService`. Remaining proof gaps are live trusted-chat evidence and live runtime/process diagnostics rather than local state-owner migration.

## Goal F: Capability Drift And Changelog Adoption

Success: each relevant Codex changelog capability is either adopted, tested unavailable with exact blocker text, or explicitly deferred with a reason.

Evidence:
- Capability cache freshness is visible in status/doctor.
- Browser, Chrome, Computer Use, apps/connectors, and dynamic MCP calls report callable/blocked/unsupported separately.
- Changelog adoption table is refreshed after Codex upgrades.

Current status: partially complete; refresh after every Codex CLI/app-server upgrade.
