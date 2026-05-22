import Foundation

public func appServerCallbackSmokeResponse(method: String, params: [String: Any]?, answer: String) -> [String: Any] {
    switch method {
    case "item/tool/requestUserInput":
        return ["result": ["answers": appServerUserInputAnswers(params: params, answer: answer)]]
    case "mcpServer/elicitation/request":
        return [
            "result": [
                "action": "accept",
                "content": [
                    "answer": answer,
                    "response": answer,
                    "confirmed": true
                ],
                "_meta": NSNull()
            ]
        ]
    default:
        return ["result": ["answer": answer]]
    }
}

private func appServerUserInputAnswers(params: [String: Any]?, answer: String) -> [String: Any] {
    let questions = params?["questions"] as? [[String: Any]] ?? []
    var answers: [String: Any] = [:]
    for (index, question) in questions.enumerated() {
        let candidateId = (question["id"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let id = candidateId.isEmpty ? "answer\(index + 1)" : candidateId
        answers[id] = ["answers": [answer]]
    }
    if answers.isEmpty {
        answers["answer"] = ["answers": [answer]]
    }
    return answers
}
