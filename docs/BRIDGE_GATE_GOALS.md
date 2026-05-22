# Apple Messages Bridge Gate Goals

This file is the working gate list for continuous bridge hardening. A gate is complete only when fake-runtime tests, live smoke evidence, status/doctor visibility, and installed-helper behavior agree.

The continuous-goals contract for this workstream lives in `docs/BRIDGE_CONTINUOUS_GOALS.md`. Use `swift run codexmsgctl-swift gates` or `/codex gates` for the current non-destructive checklist of deterministic gates, live CLI smoke commands, and trusted Messages commands. Use `swift run codexmsgctl-swift trusted-gates` to inspect real trusted-chat inbound/outbound row evidence.

## Goal 1: Outbound Delivery Truth

Success means outbound text and media can never look successful when Messages recorded a failed row.

- Deterministic gates:
  - Text evidence finds `message.text` and `message.attributedBody`.
  - Attachment evidence records row id, `message.error`, `attachment.transfer_state`, and `date_delivered`.
  - Failed sends are retryable and visible in `/status`, `/codex status`, and `codexmsgctl-swift status`.
  - `/codex smoke text` and `/codex smoke attachment` run the same delivery path from Messages and report the recorded evidence.
  - Attachment verification waits for delayed Messages DB rows and preserves SMS failed-row evidence.
- Live gates:
  - `swift run codexmsgctl-swift smoke text` passes with an outgoing Messages row.
  - `swift run codexmsgctl-swift smoke attachment` passes for an image attachment row, or fails with exact DB evidence.
- Current status:
  - Text smoke passed on row 731.
  - Current text smoke passed on row 745 with marker `CODEXMSGCTL_SMOKE_TEXT_4900E017-5AB5-482C-A02E-47099DB5664A`.
  - Post-restart text smoke passed on row 747 with marker `CODEXMSGCTL_SMOKE_TEXT_6FCFBD88-EDB4-479C-B949-B9B1B12ACAA0`.
  - Post-classifier/media-restart text smoke passed on row 749 with marker `CODEXMSGCTL_SMOKE_TEXT_3F39B797-5016-4F66-9F57-03DDAD7E2F1A`; `message.error=0`, `date_delivered=0`, and the DB row was observed.
  - Current post-app-server-smoke text smoke passed on row 751 with marker `CODEXMSGCTL_SMOKE_TEXT_2F902340-AC0A-4729-A146-EF739E051209`; `message.error=0`, `date_delivered=0`, and the DB row was observed.
  - Old file-attachment smoke exposed row 732 with `error=25`, `transfer_state=6`; this was useful evidence but not the final image-media gate.
  - Image attachment smoke passed on row 737 after normalizing the configured phone handle before opening the `sms:` URL; Messages renamed the pasted image to `IMG_5972.jpeg`, so verification uses the DB baseline row instead of requiring the marker in `transfer_name`.
  - A later image attachment smoke hit a no-row AppleScript/clipboard failure after baseline row 743. Attachment verification now polls longer and retries once only when no Messages DB row appears; the hardened smoke then passed on row 744 with `transfer_state=5`.
  - Current attachment smoke passed on row 746 with marker `CODEXMSGCTL_SMOKE_ATTACHMENT_B28DE88E-10AF-44FA-8043-A8FE4EAE37AE` after clipboard retry 2; Messages renamed the image to `IMG_1669.jpeg`.
  - Post-restart attachment smoke passed on row 748 with marker `CODEXMSGCTL_SMOKE_ATTACHMENT_0B03A564-0DDA-4429-93DC-97C65995A72E`; Messages renamed the image to `IMG_3577.jpeg`, `message.error=0`, `transfer_state=5`.
  - Post-classifier/media-restart attachment smoke passed on row 750 with marker `CODEXMSGCTL_SMOKE_ATTACHMENT_F8524182-A855-4B0C-854B-E1B061FF1E2B`; Messages renamed the image to `IMG_2008.jpeg`, `message.error=0`, `transfer_state=5`, after clipboard retry 2.
  - Current post-app-server-smoke attachment smoke passed on row 752 with marker `CODEXMSGCTL_SMOKE_ATTACHMENT_97C66EAF-75BE-4839-9F51-1A31484A7791`; Messages renamed the image to `IMG_1774.jpeg`, `message.error=0`, `transfer_state=5`, after clipboard retry 2.
  - `/codex smoke attachment` now sends a marked image probe from the Messages command surface and keeps the probe as `lastOutboundSend` while sending an unrecorded summary reply.
  - Fake-runtime coverage now verifies delayed attachment rows are observed after AppleScript returns, and SMS attachment sends pass the SMS service type while surfacing `error=25`/`transfer_state=6` evidence.

## Goal 2: Media Continuity

Success means follow-up prompts like "modify that image" use a real previous chat image or stop and ask for the source.

- Deterministic gates:
  - Recent inbound and outbound image refs persist in `BridgeState`.
  - A previous-image follow-up attaches the latest usable image for that chat.
  - A previous-image follow-up with no usable image asks for the source and does not start Codex.
  - Final replies containing `BRIDGE_ATTACH:` send the attachment before any success text, and failed attachment delivery prevents the success text from being sent.
  - `/codex smoke bridge-attach` and `codexmsgctl-swift smoke bridge-attach` exercise a final-reply-style `BRIDGE_ATTACH:` directive rather than direct attachment sending.
  - `/codex smoke generated-image` asks a real app-server turn to create a marked PNG at a bridge temp path and reply with `BRIDGE_ATTACH:`; deterministic coverage verifies the generated artifact is attached before success text.
  - Messages DB ingress covers attachment-only rows, multiple attachments, `~/` path expansion, image/PDF/unsupported classification, and existence flags.
- Live gates:
  - Send an inbound image, then ask for a marked modification; app-server receives a `localImage`.
  - Ask for a generated image and verify `BRIDGE_ATTACH` delivery evidence.
  - Send a marked outbound image through the bridge, then ask app-server about "that image" and verify it receives the exact outbound image as a `localImage`.
- Current status:
  - `codexmsgctl-swift status` and `/codex status` now expose the recent media registry.
  - State saves now merge `recentMediaRefs` so unrelated helper/CLI saves cannot erase the image registry used by "that image" follow-ups.
  - Very recent inbound rows with attachment paths that are not readable yet are now deferred without advancing the Messages cursor. The bridge retries the same row on later ticks, processes it once the file appears, and stops deferring after the short missing-attachment window so permanently missing files cannot wedge the helper.
  - `swift run codexmsgctl-swift smoke inbound-image-check` now validates the current recent inbound image registry, builds a "that image" follow-up, verifies the local image is attached to the app-server request, and then runs a marked app-server probe.
  - If the registry is empty or contains only app-server-incompatible images, inbound-image smoke can recover the latest trusted inbound image from Messages DB and persist it back into `state.json`.
  - HEIC/HEIF/TIFF/WebP/BMP inbound images recovered from Messages DB are converted to JPEG before app-server invocation, so the smoke verifies an attachable local image rather than accepting an unsupported-image blocker.
  - Previous-image follow-up selection now skips unsupported recent image refs such as HEIC when choosing a source for app-server image input, and status marks those refs as `app-server-unsupported`.
  - Live `swift run codexmsgctl-swift smoke inbound-image-check` passed with marker `CODEXMSGCTL_SMOKE_INBOUND_IMAGE_3A6D9799-EE48-453C-8220-AA8C2F255A3B`: it recovered trusted inbound row 721 (`IMG_5685.HEIC`), converted it to a temp JPEG, and app-server replied `SUCCESS`.
  - A second live inbound-image smoke passed from the persisted converted media ref with marker `CODEXMSGCTL_SMOKE_INBOUND_IMAGE_5BF48A3C-C0CA-4A82-BAC3-52019F6E86F6`, proving the registry path works after recovery.
  - Current inbound-image smoke passed from persisted converted row 721 with marker `CODEXMSGCTL_SMOKE_INBOUND_IMAGE_5B6E7633-55B2-4AC4-84FC-CDF4BA033A67`, thread `019e4f1c-56de-7741-9a0f-34894af6d9c3`, and turn `019e4f1c-58e7-7122-a970-152c225300ba`.
  - `/codex smoke outbound-image-check` and `codexmsgctl-swift smoke outbound-image-check` now send a marked image, persist it as a recent outbound media ref, build a "that image" app-server request, and require marker plus `SUCCESS`.
  - Live `swift run codexmsgctl-swift smoke outbound-image-check` passed with marker `CODEXMSGCTL_SMOKE_OUTBOUND_IMAGE_D0F56FCE-D2CE-4953-9B01-C1022ADE34F0`: Messages DB row 753 (`message.error=0`, `transfer_state=5`, renamed to `IMG_7646.jpeg`), app-server thread `019e4f2f-3cf5-7b20-813b-d6c4598f6b0e`, and turn `019e4f2f-3f08-7961-a78c-490f507e8073`.
  - Media final replies now send validated attachments before success text. Deterministic coverage verifies `Done.` is not sent when the attachment delivery path fails.
  - Live `swift run codexmsgctl-swift smoke bridge-attach` passed with marker `CODEXMSGCTL_SMOKE_BRIDGE_ATTACH_136C4E7D-091D-4DA8-8AD3-03877F392FF2`: Messages DB attachment row 756 (`message.error=0`, `transfer_state=5`, renamed to `IMG_8173.jpeg`) was observed before success text row 757 (`message.error=0`).
  - `/codex smoke generated-image` is now available as a trusted-chat live gate for app-server-produced media; live evidence is still pending.

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
  - Current live smoke passed for `bridge-smoke-test-8fd10e85` with marker `CODEXMSGCTL_SMOKE_AUTOMATION_2B366AD1-1F91-45B3-99C9-6B728FD10E85`.
  - Current post-app-server-smoke automation smoke passed for `bridge-smoke-test-0a76716f` with marker `CODEXMSGCTL_SMOKE_AUTOMATION_162A28FB-86ED-4E98-B083-5A6F0A76716F`; status showed `Automation creation status: confirmed` and route persisted with active job `none`.
  - `codexmsgctl-swift status` now reports automation creation status and the latest automation routes.
  - State saves now merge automation route/status fields so a helper tick with stale in-memory state cannot erase a newly persisted route.
  - Automation creation classification now has a phrase matrix covering creation/reminder/monitor/follow-up positives plus management/debug/list/status and ordinary schedule false positives.

## Goal 4: Interactive Callback Parity

Success means app-server `item/tool/requestUserInput` and `mcpServer/elicitation/request` can pause through Messages, accept the next trusted reply, resume the original turn, and time out visibly.

- Deterministic gates:
  - Pending callback state survives state saves.
  - Inbound reply routing goes to the callback instead of a new prompt.
  - Cancel and timeout answer the app-server request and clear state.
- Architecture gate:
  - The backend now has a JSON-RPC responder channel for app-server callbacks. The remaining proof is live installed-helper evidence from Apple Messages via `/codex smoke app-server-callback`.
- Current status:
  - State saves now preserve non-terminal `pendingInteractiveCallback` records across stale helper/CLI saves while still allowing terminal callbacks to clear.
  - Inbound trusted non-command replies now route to pending callback state instead of starting a new prompt batch, recording response text/row/guid and sending a visible acknowledgement.
  - `/cancel` and callback expiration now clear pending callback state and send visible Messages feedback.
  - `CodexAppServerBackend` now accepts an interactive callback responder and can return real JSON-RPC results for `item/tool/requestUserInput` and `mcpServer/elicitation/request` instead of always emitting the unsupported error.
  - The default bridge backend now persists a pending callback, messages the user, waits for the routed answer, returns app-server-shaped callback results, and clears terminal callback state.
  - Deterministic coverage now runs a `BridgeService` end-to-end callback flow through the default backend responder seam: fake app-server asks for input, the bridge sends the Messages prompt, the next trusted reply is captured, the responder returns structured answers, the original turn sends its final answer, and pending/active state clears.
  - `/codex smoke callback` now creates a pending callback from Apple Messages and verifies that the next trusted non-command reply is captured by the callback route, reports the captured row/guid/text, clears pending state, and does not start a normal Codex job. Deterministic coverage exercises the two-message flow.
  - `/codex smoke app-server-callback` now starts a real app-server turn from Apple Messages with a prompt that must use app-server interactive user input before final answer. Deterministic coverage proves the command starts the default backend, sends the callback prompt, routes the trusted reply, and completes the original turn.
  - Remaining gap: this still needs a trusted live run that proves the installed helper can trigger the real app-server callback, receive the next trusted reply, and complete the original Codex turn end to end.

## Goal 5: Runtime State And Process Supervision

Success means bridge state writes cannot clobber each other and cancellation leaves no orphan app-server or tool descendants.

- Deterministic gates:
  - Corrupt `state.json` is backed up and defaulted.
  - Cancel kills the known process tree.
  - Simultaneous tick/callback/cancel/send-record updates preserve unrelated fields.
- Current status:
  - Deterministic coverage now verifies stale state saves preserve concurrently added automation route/status fields and recent media refs while still accepting incoming cursor updates.
  - The same stale-save coverage now includes non-terminal pending interactive callbacks and last outbound send evidence, including protection against downgrading completed send evidence back to an in-flight state.
  - Same-active-job state saves now merge process/thread/turn/output metadata, latest progress timestamps, permission recovery fields, and still allow terminal active-job clears.
  - JSON state writes are now serialized by state-file path across separate `RuntimeStores` instances, and the store exposes an atomic `update` helper. Deterministic coverage verifies concurrent route/media updates from different store objects cannot drop either field.
  - `BridgeService` now keeps in-memory state in a serialized `BridgeStateBox` instead of an unlocked struct plus scattered ad hoc locks. Deterministic coverage verifies concurrent in-memory mutations cannot drop media refs while updating the cursor.
  - Cursor updates, outbound delivery evidence, recent media refs, active-job updates, callback completion, and `/cancel` state transitions now pass through serialized mutation helpers. Cancel still saves the terminal callback state before clearing it so the merge layer cannot resurrect a pending callback.
  - Prompt job-start, `/reset`, Codex session start/resume/expiry, session id capture, and session completion/error timestamps now pass through serialized mutation helpers. A source-level architecture regression prevents those paths from reintroducing direct session/job-start assignment patterns.
  - App-server connection close now terminates the process tree before closing stdin, preventing timeout cleanup from orphaning app-server child processes.
  - Deterministic coverage now runs a fake app-server that spawns a child process and verifies timeout cleanup removes the child.
  - Doctor now parses app-server process snapshots by pid, parent pid, process group, elapsed time, and transport, and flags orphaned `stdio://` app-server processes separately from long-lived `unix://` or desktop app-server processes.
  - Synchronous doctor probes now have a default timeout, and doctor uses cached capability inventory for status instead of blocking on a fresh app-server inventory refresh.
  - Doctor now reports corrupt `state.json` recovery backups by exact backup path when they exist. Deterministic coverage verifies the latest backup path is discoverable; current live doctor reports `State recovery backups: none`.
  - Doctor now reports helper and permission-broker LaunchAgent loaded state plus provenance across expected installed executable path, LaunchAgent plist `ProgramArguments[0]`, and the loaded `launchctl print` program path. Current live doctor shows all three paths agree for both LaunchAgents.
  - Doctor now compares built helper/broker executables with the installed runtime copies and reports byte-level match/mismatch when both artifacts exist. Deterministic coverage verifies match, mismatch, and missing-built-artifact behavior.
  - Current live doctor reports built-vs-installed identity matches for the helper (`3367392` bytes) and permission broker (`3430304` bytes), with matching built/installed mtimes.
- Live gates:
  - Doctor reports app-server process snapshots without hanging.
  - Cancel/timeout leaves no bridge-owned orphan `codex app-server` or Computer Use child process.

## Goal 6: Capability And Version Drift

Success means the bridge continuously reports what Codex can really do from Messages, and each relevant Codex changelog capability is adopted, tested unavailable, or explicitly deferred.

- Deterministic gates:
  - Capability cache separates discovered, callable, blocked, and unsupported.
  - Browser, Chrome, Computer Use, and app connector probes report exact blockers.
  - Dynamic app-server tool forwarding has contract coverage for MCP success, MCP error content, unsupported non-MCP namespaces, malformed request fields, images, primitives, and unknown JSON object content with searchable keys.
  - Stalled dynamic MCP forwarding returns a structured tool failure, includes the timed-out app-server response id, and closes the app-server connection.
- Live gates:
  - `doctor --probe-computer-use` returns within its timeout and prints exact blocker text.
  - `/codex status` agrees with `codexmsgctl-swift status` about callable tools.
- Current status:
  - `swift run codexmsgctl-swift smoke computer-use` passed with real `list_apps` and `get_app_state` calls and marker `CODEXMSGCTL_SMOKE_COMPUTER_USE_2AFB06AB-BA16-4C44-B947-5543EEBB8654`.
  - Later `swift run codexmsgctl-swift doctor --probe-computer-use` runs failed twice with exact live blocker `Computer Use server error -10005: cgWindowNotFound`; this is now recorded as a live runtime condition rather than a silent fallback.
  - Current `swift run codexmsgctl-swift doctor --probe-computer-use` passed with `Computer Use probe: SUCCESS Start Page`.
  - Current `swift run codexmsgctl-swift smoke computer-use` passed with real `list_apps` and `get_app_state` calls and marker `CODEXMSGCTL_SMOKE_COMPUTER_USE_D076BC6E-2948-4C7B-94A3-E7AFFC703587`.
  - Current smoke computer-use passed again with marker `CODEXMSGCTL_SMOKE_COMPUTER_USE_C809B0CA-D913-4040-9B3A-5A5DB1CF9D2E`.
  - A later `doctor --probe-computer-use` run returned without hanging and failed visibly with exact blocker `BLOCKED Computer Use server error -10005: cgWindowNotFound`.
  - Current `swift run codexmsgctl-swift doctor --probe-computer-use` uses the same marker-based Computer Use prompt as smoke and passed with marker `CODEX_DOCTOR_COMPUTER_USE_D98B1A76-6117-48FC-96E0-B660287BE5B0`, response `SUCCESS Start Page`.
  - `swift run codexmsgctl-swift smoke chrome` invoked the Chrome skill path and returned the exact blocker `privileged native pipe bridge is not available; browser-client is not trusted` with marker `CODEXMSGCTL_SMOKE_CHROME_9E2AAA1F-51AE-44D3-9B60-6A63DBEED695`.
  - Current `swift run codexmsgctl-swift smoke chrome` still reports the expected blocker with marker `CODEXMSGCTL_SMOKE_CHROME_BF716326-E9E4-40FF-A47A-173DB6A40F3A`.
  - Current smoke chrome still reports the expected blocker with marker `CODEXMSGCTL_SMOKE_CHROME_AFFEEED9-3DCA-469B-AC95-CF261D565C74`.
  - Post-dynamic-tool-contract smoke chrome passed with marker `CODEXMSGCTL_SMOKE_CHROME_576B25C3-DDA5-47B2-9221-ACEC6F3EDAC9` and exact blocker `privileged native pipe bridge is not available; browser-client is not trusted`.
  - Post-classifier-restart `swift run codexmsgctl-swift smoke computer-use` passed with marker `CODEXMSGCTL_SMOKE_COMPUTER_USE_76A2D932-9377-4AD0-A1E5-B91A4747AB10` and exact blocker `Computer Use server error -10005: cgWindowNotFound`.
  - Current capability smokes passed with exact results: Chrome marker `CODEXMSGCTL_SMOKE_CHROME_EECDCD30-9A25-42BA-B67D-869D8C5F6ABB` blocked by `privileged native pipe bridge is not available; browser-client is not trusted`; Browser marker `CODEXMSGCTL_SMOKE_BROWSER_99BE312F-8601-418D-AEC9-3CBEA61ACDA0` blocked by `Browser is not available: iab`; Computer Use marker `CODEXMSGCTL_SMOKE_COMPUTER_USE_3A921966-16AC-4650-82D4-27825778951F` succeeded with `Start Page`.
  - `swift run codexmsgctl-swift smoke browser` invoked the Browser skill path and returned the exact blocker `Browser is not available: iab` with marker `CODEXMSGCTL_SMOKE_BROWSER_9BC2108C-E062-4CA4-8F74-CD305E23A487`.
  - Current `swift run codexmsgctl-swift smoke browser` still reports the expected blocker with marker `CODEXMSGCTL_SMOKE_BROWSER_8A9C61EA-F7B0-451F-8BC4-E261E15DAFAD`.
  - Current smoke browser still reports the expected blocker with marker `CODEXMSGCTL_SMOKE_BROWSER_F03F2AD3-962F-4A33-8C8E-09CCE3734F69`.
  - `codexmsgctl-swift smoke` now has standalone `chrome`, `browser`, and `computer-use` subcommands that print app-server pid, thread id, turn id, progress, final response, and blocker text.
  - Doctor's Computer Use probe now shares the same hardened marker prompt as `smoke computer-use`, so health checks and capability smoke no longer drift in behavior.
  - `codexmsgctl-swift status` and `/codex status` now use the capability cache first and bound live refresh attempts, so a stuck app-server capability refresh cannot hang status. Deterministic coverage verifies the best-effort status lookup returns an existing cache even when the Codex command is unavailable.
  - `codexmsgctl-swift trusted-gates` now reports whether trusted Messages gate commands have real inbound rows and nearby outbound reply rows, including outbound `message.error` values.
  - Capability cache formatting now marks caches stale after 24h in status and doctor output, so version/tool drift is visible even when bounded refreshes are skipped.
  - Dynamic tool forwarding now has deterministic stalled-call coverage using a fake app-server connection that waits until the RPC deadline, then verifies the bridge sends an explicit failed tool result for the original dynamic call.
  - `codexmsgctl-swift smoke app-server` and `/codex smoke app-server` now run a no-tool marked app-server turn and require the final response to contain the marker plus `SUCCESS`.
  - Current `swift run codexmsgctl-swift smoke app-server` passed with marker `CODEXMSGCTL_SMOKE_APP_SERVER_67979A3A-523E-4A7D-8938-B9CABF065197`, thread `019e4f19-beec-70c1-8786-1ec4e10486f2`, and turn `019e4f19-c068-75d2-96ab-0fddbd3b903c`.
  - Post-restart `swift run codexmsgctl-swift status` returned with `Codex capability cache: cached at 2026-05-22T08:38:33.701Z` and callable Chrome, Computer Use, and Apps/connectors invocation status.
  - The Messages command surface now recognizes `/codex smoke automation`, `/codex smoke callback`, `/codex smoke inbound-image-check`, `/codex smoke chrome`, `/codex smoke browser`, and `/codex smoke computer-use`, so capability probes can be launched from Apple Messages instead of only from the CLI. Deterministic coverage verifies `/codex smoke chrome` invokes the app-server probe path and returns thread/turn evidence in the reply.
  - Post-restart `swift run codexmsgctl-swift smoke chrome` passed with marker `CODEXMSGCTL_SMOKE_CHROME_33E4142A-6BDF-4224-A9BD-2D7148DAACCA` and exact blocker `privileged native pipe bridge is not available; browser-client is not trusted`.

## Required Green Gate Set

Before this workstream is complete, the installed helper must satisfy:

- `swift run BridgeCoreTests`
- `swift run BridgeCoreSelfTest`
- `swift test`
- `swift run codexmsgctl-swift doctor --probe-computer-use`
- `swift run codexmsgctl-swift gates`
- `swift run codexmsgctl-swift trusted-gates`
- `swift run codexmsgctl-swift smoke text`
- `swift run codexmsgctl-swift smoke attachment`
- `swift run codexmsgctl-swift smoke bridge-attach`
- `swift run codexmsgctl-swift smoke app-server`
- `swift run codexmsgctl-swift smoke inbound-image-check`
- `swift run codexmsgctl-swift smoke outbound-image-check`
- `/codex status` from the trusted Messages chat
- A live inbound-image follow-up edit probe
- A live automation creation/list/delivery probe
- A live Browser/Chrome/Computer Use blocker-or-success probe
