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

public func normalizedSQLHandleExpression(_ column: String) -> String {
    var expression = "coalesce(\(column), '')"
    for character in ["+", "-", " ", "(", ")", "."] {
        expression = "replace(\(expression), '\(character)', '')"
    }
    return expression
}
