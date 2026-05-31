import Foundation

extension BridgeState {
    mutating func applyAutomationCreationStatus(
        origin: MessageItem?,
        phase: String,
        automationId: String?,
        name: String?,
        createdFilePath: String?,
        routeStatus: String?,
        confirmationSendStatus: String?,
        failureText: String?,
        updatedAt: String
    ) {
        automationCreationStatus = AutomationCreationStatus(
            automationId: automationId ?? automationCreationStatus?.automationId,
            name: name ?? automationCreationStatus?.name,
            sourceRowId: origin?.rowId,
            sourceGuid: origin?.guid,
            phase: phase,
            createdFilePath: createdFilePath ?? automationCreationStatus?.createdFilePath,
            routeStatus: routeStatus ?? automationCreationStatus?.routeStatus,
            confirmationSendStatus: confirmationSendStatus ?? automationCreationStatus?.confirmationSendStatus,
            failureText: failureText,
            updatedAt: updatedAt
        )
    }

    mutating func upsertAutomationRoute(_ route: CodexAutomationRoute) {
        automationRoutes = upsertCodexAutomationRoute(route, into: automationRoutes ?? [])
    }

    mutating func markAutomationRouteDelivered(automationId: String, sessionId: String, deliveredAt: String) {
        guard let index = automationRoutes?.firstIndex(where: { $0.automationId == automationId }) else { return }
        automationRoutes?[index].lastSeenSessionId = sessionId
        automationRoutes?[index].lastDeliveredSessionId = sessionId
        automationRoutes?[index].lastDeliveredAt = deliveredAt
    }
}
