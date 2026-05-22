# Apple Messages Bridge Gate Goals

This file is the working gate list for continuous bridge hardening. A gate is complete only when fake-runtime tests, live smoke evidence, status/doctor visibility, and installed-helper behavior agree.

## Goal 1: Outbound Delivery Truth

Success means outbound text and media can never look successful when Messages recorded a failed row.

- Deterministic gates:
  - Text evidence finds `message.text` and `message.attributedBody`.
  - Attachment evidence records row id, `message.error`, `attachment.transfer_state`, and `date_delivered`.
  - Failed sends are retryable and visible in `/status`, `/codex status`, and `codexmsgctl-swift status`.
- Live gates:
  - `swift run codexmsgctl-swift smoke text` passes with an outgoing Messages row.
  - `swift run codexmsgctl-swift smoke attachment` passes for an image attachment row, or fails with exact DB evidence.
- Current status:
  - Text smoke passed on row 731.
  - Old file-attachment smoke exposed row 732 with `error=25`, `transfer_state=6`; this was useful evidence but not the final image-media gate.
  - Image attachment smoke passed on row 737 after normalizing the configured phone handle before opening the `sms:` URL; Messages renamed the pasted image to `IMG_5972.jpeg`, so verification uses the DB baseline row instead of requiring the marker in `transfer_name`.

## Goal 2: Media Continuity

Success means follow-up prompts like "modify that image" use a real previous chat image or stop and ask for the source.

- Deterministic gates:
  - Recent inbound and outbound image refs persist in `BridgeState`.
  - A previous-image follow-up attaches the latest usable image for that chat.
  - A previous-image follow-up with no usable image asks for the source and does not start Codex.
- Live gates:
  - Send an inbound image, then ask for a marked modification; app-server receives a `localImage`.
  - Ask for a generated image and verify `BRIDGE_ATTACH` delivery evidence.
- Current status:
  - `codexmsgctl-swift status` and `/codex status` now expose the recent media registry.
  - State saves now merge `recentMediaRefs` so unrelated helper/CLI saves cannot erase the image registry used by "that image" follow-ups.
  - `swift run codexmsgctl-swift smoke inbound-image-check` now validates the current recent inbound image registry, builds a "that image" follow-up, verifies the local image is attached to the app-server request, and then runs a marked app-server probe.
  - Current live precondition result: no usable recent inbound image is registered yet for the trusted chat, so the smoke fails visibly and tells the operator to send a trusted image first.

## Goal 3: Automation Truth

Success means Messages-triggered automation creation is bridge-owned, synchronous, observable, and never contradicted by a later normal Codex reply.

- Deterministic gates:
  - Automation creation writes a real `automation.toml`.
  - Creation does not start a normal active Codex job.
  - `/codex automations` reports in-flight creation status.
  - Completed automation sessions are forwarded once.
- Live gates:
  - A marked automation creation request produces one truthful confirmation.
  - `/codex automations` shows the route or the exact in-progress/failure phase.
- Current status:
  - `swift run codexmsgctl-swift smoke automation` creates a real paused `automation.toml`, persists its route, and records `automationCreationStatus`.
  - Live smoke passed for `bridge-smoke-test-7431ce30` with marker `CODEXMSGCTL_SMOKE_AUTOMATION_B219F241-59D2-449C-BF80-244C7431CE30`.
  - `codexmsgctl-swift status` now reports automation creation status and the latest automation routes.
  - State saves now merge automation route/status fields so a helper tick with stale in-memory state cannot erase a newly persisted route.

## Goal 4: Interactive Callback Parity

Success means app-server `item/tool/requestUserInput` and `mcpServer/elicitation/request` can pause through Messages, accept the next trusted reply, resume the original turn, and time out visibly.

- Deterministic gates:
  - Pending callback state survives state saves.
  - Inbound reply routing goes to the callback instead of a new prompt.
  - Cancel and timeout answer the app-server request and clear state.
- Architecture gate:
  - The backend needs a live JSON-RPC responder channel. Persisted state alone is not enough because the current `CodexBackend.invoke` call has no way to resume a held server request after the bridge waits for a future Messages row.
- Current status:
  - State saves now preserve non-terminal `pendingInteractiveCallback` records across stale helper/CLI saves while still allowing terminal callbacks to clear.

## Goal 5: Runtime State And Process Supervision

Success means bridge state writes cannot clobber each other and cancellation leaves no orphan app-server or tool descendants.

- Deterministic gates:
  - Corrupt `state.json` is backed up and defaulted.
  - Cancel kills the known process tree.
  - Simultaneous tick/callback/cancel/send-record updates preserve unrelated fields.
- Current status:
  - Deterministic coverage now verifies stale state saves preserve concurrently added automation route/status fields and recent media refs while still accepting incoming cursor updates.
  - The same stale-save coverage now includes non-terminal pending interactive callbacks.
- Live gates:
  - Doctor reports app-server process snapshots without hanging.
  - Cancel/timeout leaves no bridge-owned orphan `codex app-server` or Computer Use child process.

## Goal 6: Capability And Version Drift

Success means the bridge continuously reports what Codex can really do from Messages, and each relevant Codex changelog capability is adopted, tested unavailable, or explicitly deferred.

- Deterministic gates:
  - Capability cache separates discovered, callable, blocked, and unsupported.
  - Browser, Chrome, Computer Use, and app connector probes report exact blockers.
- Live gates:
  - `doctor --probe-computer-use` returns within its timeout and prints exact blocker text.
  - `/codex status` agrees with `codexmsgctl-swift status` about callable tools.
- Current status:
  - `swift run codexmsgctl-swift smoke computer-use` passed with real `list_apps` and `get_app_state` calls and marker `CODEXMSGCTL_SMOKE_COMPUTER_USE_2AFB06AB-BA16-4C44-B947-5543EEBB8654`.
  - `swift run codexmsgctl-swift smoke chrome` invoked the Chrome skill path and returned the exact blocker `privileged native pipe bridge is not available; browser-client is not trusted` with marker `CODEXMSGCTL_SMOKE_CHROME_9E2AAA1F-51AE-44D3-9B60-6A63DBEED695`.
  - `swift run codexmsgctl-swift smoke browser` invoked the Browser skill path and returned the exact blocker `Browser is not available: iab` with marker `CODEXMSGCTL_SMOKE_BROWSER_9BC2108C-E062-4CA4-8F74-CD305E23A487`.
  - `codexmsgctl-swift smoke` now has standalone `chrome`, `browser`, and `computer-use` subcommands that print app-server pid, thread id, turn id, progress, final response, and blocker text.

## Required Green Gate Set

Before this workstream is complete, the installed helper must satisfy:

- `swift run BridgeCoreTests`
- `swift run BridgeCoreSelfTest`
- `swift test`
- `swift run codexmsgctl-swift doctor --probe-computer-use`
- `swift run codexmsgctl-swift smoke text`
- `swift run codexmsgctl-swift smoke attachment`
- `swift run codexmsgctl-swift smoke inbound-image-check`
- `/codex status` from the trusted Messages chat
- A live inbound-image follow-up edit probe
- A live automation creation/list/delivery probe
- A live Browser/Chrome/Computer Use blocker-or-success probe
