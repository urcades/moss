# Apple Messages Bridge Continuous Goals

This is the working contract for continuing bridge hardening until every gate in `BRIDGE_GATE_GOALS.md` is proven. A goal is complete only when deterministic tests, live smoke evidence, installed-helper behavior, and status/doctor output agree.

## Goal A: Local Gate Harness

Success: one command can run or clearly enumerate every non-destructive local gate, including `BridgeCoreTests`, `BridgeCoreSelfTest`, `swift test`, `doctor --probe-computer-use`, and CLI smoke probes.

Evidence:
- Command output shows pass/fail for each local gate with marker ids, row ids, thread ids, turn ids, or blocker text where applicable.
- Gate docs record the latest live evidence.

Current status: in progress. Individual commands exist, `codexmsgctl-swift gates` prints the complete deterministic, live CLI, and trusted Messages gate checklist with current readiness hints, and `/codex gates` exposes the same checklist from Apple Messages.

## Goal B: Trusted Messages Gate Harness

Success: trusted-chat commands can prove `/codex status` and every `/codex smoke ...` surface from Apple Messages, and the CLI can summarize the required inbound command, observed inbound row, outbound reply row, marker, and delivery evidence.

Evidence:
- `/codex status` from the trusted chat agrees with `codexmsgctl-swift status`.
- Trusted-chat `/codex smoke app-server`, `text`, `attachment`, `automation`, `callback`, `inbound-image-check`, `outbound-image-check`, `chrome`, `browser`, and `computer-use` have observed inbound rows and outgoing reply evidence.
- `codexmsgctl-swift trusted-gates` reports each trusted command as `observed`, `missing-inbound`, `missing-outbound`, or `outbound-error-*` from Messages DB evidence.

Current status: in progress and partly externally gated, because true trusted inbound rows must come from Apple Messages rather than this process sending `is_from_me=1` rows. `codexmsgctl-swift trusted-gates` now observes real inbound/outbound row evidence without sending messages.

## Goal C: Real Callback Parity

Success: a real app-server-generated `item/tool/requestUserInput` or `mcpServer/elicitation/request` pauses through the installed helper, sends the prompt to Messages, captures the next trusted reply, returns the JSON-RPC response, and completes the original turn.

Evidence:
- Fake-runtime callback tests pass.
- A live installed-helper smoke records callback id, inbound prompt row, trusted reply row/guid, app-server thread/turn id, and final answer.

Current status: deterministic support exists; live real-callback proof is missing.

## Goal D: Media Delivery And Editing Truth

Success: generated media and follow-up edits never claim success unless a validated attachment send happened, and follow-up prompts reuse the correct recent inbound or outbound image.

Evidence:
- CLI and Messages smoke can prove inbound-image and outbound-image continuity with local image inputs.
- A live generated-image `BRIDGE_ATTACH:` flow records delivery row/error/transfer state.
- A live edit follow-up uses the previous real image or asks for the source.

Current status: inbound/outbound continuity smoke exists; generated-image and live edit probes remain.

## Goal E: State Owner And Process Supervision

Success: state mutation is single-owner or versioned enough that simultaneous tick, callback, cancel, send-record, automation, and CLI writes cannot clobber unrelated fields; timeout/cancel leaves no bridge-owned process descendants.

Evidence:
- Concurrency tests cover separate store instances and simultaneous service mutations.
- Doctor reports app-server process groups and orphan checks.
- Timeout/cancel tests verify process-tree cleanup.

Current status: field merge and path-scoped state write locking exist; the full actor/reducer migration is still open.

## Goal F: Capability Drift And Changelog Adoption

Success: each relevant Codex changelog capability is either adopted, tested unavailable with exact blocker text, or explicitly deferred with a reason.

Evidence:
- Capability cache freshness is visible in status/doctor.
- Browser, Chrome, Computer Use, apps/connectors, and dynamic MCP calls report callable/blocked/unsupported separately.
- Changelog adoption table is refreshed after Codex upgrades.

Current status: partially complete; refresh after every Codex CLI/app-server upgrade.
