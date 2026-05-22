import Foundation

public struct InboundImageSmokeRequest: Equatable, Sendable {
    public var marker: String
    public var mediaRef: RecentMediaRef
    public var request: PromptRequest

    public init(marker: String, mediaRef: RecentMediaRef, request: PromptRequest) {
        self.marker = marker
        self.mediaRef = mediaRef
        self.request = request
    }
}

public func buildInboundImageSmokeRequest(
    recipient: String,
    service: String,
    recentMediaRefs: [RecentMediaRef],
    now: Date = Date(),
    marker: String = "CODEXMSGCTL_SMOKE_INBOUND_IMAGE_\(UUID().uuidString)"
) throws -> InboundImageSmokeRequest {
    guard let ref = recentMediaRefs.reversed().first(where: { mediaRef in
        mediaRef.direction == "inbound" &&
            mediaRef.kind == "image" &&
            mediaRef.handleId == recipient &&
            mediaRef.service == service &&
            mediaRef.exists &&
            FileManager.default.fileExists(atPath: mediaRef.path)
    }) else {
        throw StoreError.validation("Smoke inbound-image-check failed: no usable recent inbound image for \(recipient) via \(service). Send a trusted image to the bridge first, wait for status to show it under Recent media refs, then rerun this smoke.")
    }
    let nowText = DateCodec.iso(now)
    let batch = PendingBatch(
        handleId: recipient,
        service: service,
        startedAt: nowText,
        deadlineAt: nowText,
        items: [
            MessageItem(
                rowId: 0,
                guid: "codexmsgctl-smoke-\(marker)",
                text: "For that image, reply only with \(marker) SUCCESS if an image is attached, or \(marker) BLOCKED and the exact blocker text if no image is attached.",
                handleId: recipient,
                service: service,
                receivedAt: nowText,
                attachments: []
            )
        ]
    )
    let request = buildPromptRequest(from: batch, recentMediaRefs: recentMediaRefs)
    guard request.attachments.contains(where: { $0.kind == "image" && $0.absolutePath == ref.path && $0.exists }) else {
        throw StoreError.validation("Smoke inbound-image-check failed: prompt builder did not attach recent inbound image \(ref.path).")
    }
    return InboundImageSmokeRequest(marker: marker, mediaRef: ref, request: request)
}
