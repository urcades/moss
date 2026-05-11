import Foundation

public func digitsOnly(_ value: String) -> String {
    value.filter(\.isNumber)
}

public func senderAliases(_ allowedSender: String) -> [String] {
    let digits = digitsOnly(allowedSender)
    guard !digits.isEmpty else { return [] }
    var aliases: [String] = []
    func add(_ value: String) {
        if !value.isEmpty && !aliases.contains(value) {
            aliases.append(value)
        }
    }
    add(digits)
    if digits.count == 11, digits.first == "1" {
        add(String(digits.dropFirst()))
    } else if digits.count == 10 {
        add("1\(digits)")
    }
    return aliases
}

public func normalizedTrustedSenderIdentity(_ value: String) -> String {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return "" }
    if trimmed.contains("@") {
        return trimmed.lowercased()
    }
    let digits = digitsOnly(trimmed)
    if digits.count >= 7 {
        return digits
    }
    return trimmed.lowercased()
}

public func trustedSenderComparisonValues(_ sender: String) -> [String] {
    let trimmed = sender.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return [] }
    let aliases = senderAliases(trimmed)
    if !aliases.isEmpty {
        return aliases
    }
    return [trimmed.lowercased()]
}

public func normalizedSQLHandleExpression(_ column: String) -> String {
    var expression = "coalesce(\(column), '')"
    for character in ["+", "-", " ", "(", ")", "."] {
        expression = "replace(\(expression), '\(character)', '')"
    }
    return expression
}
