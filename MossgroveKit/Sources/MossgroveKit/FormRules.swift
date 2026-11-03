import Foundation

/// The club form's fields, as typed.
public struct ClubForm: Equatable, Sendable {
    public var name = ""
    public var email = ""
    public var age = ""
    public var password = ""
    public var aisle: Aisle?
    public var deliveryDate: Date?
    public var newsletter = false
    public var budget = 50
    public var acceptedTerms = false

    public init() {}
}

/// One field of the form that can be wrong.
public enum FormField: String, CaseIterable, Sendable {
    case name, email, age, password, category, date, terms
}

/// One message per invalid field. The texts are part of the spec: every framework shows the same words.
public enum FormRules {
    public static let name = "Enter your name"
    public static let email = "Enter a valid email address"
    public static let age = "Enter an age from 18 to 120"
    public static let password = "Use at least 8 characters, including a number"
    public static let category = "Choose a favourite aisle"
    public static let date = "Choose a delivery date"
    public static let terms = "Accept the terms to continue"

    /// Slider: $0–200 in $10 steps, starting at $50.
    public static let budgetRange = 0.0...200.0
    public static let budgetStep = 10.0

    private static let emailShape = try! NSRegularExpression(pattern: #"^[^@\s]+@[^@\s]+\.[^@\s]+$"#)

    public static func errors(_ form: ClubForm) -> [FormField: String] {
        var errors: [FormField: String] = [:]
        if form.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { errors[.name] = name }
        let mail = form.email.trimmingCharacters(in: .whitespacesAndNewlines)
        if emailShape.firstMatch(in: mail, range: NSRange(mail.startIndex..., in: mail)) == nil { errors[.email] = email }
        if let years = Int(form.age.trimmingCharacters(in: .whitespaces)), (18...120).contains(years) {} else { errors[.age] = age }
        if form.password.count < 8 || !form.password.contains(where: \.isNumber) { errors[.password] = password }
        if form.aisle == nil { errors[.category] = category }
        if form.deliveryDate == nil { errors[.date] = date }
        if !form.acceptedTerms { errors[.terms] = terms }
        return errors
    }

    /// The Age field takes digits only, three at most.
    public static func ageInput(_ typed: String) -> String { String(typed.filter(\.isASCIIDigit).prefix(3)) }

    /// "$120": the budget as the form shows it.
    public static func budgetText(_ value: Double) -> String { "$\(Int(value.rounded()))" }

    /// "15 Nov 2026": the delivery date as every framework writes it.
    public static func formatDate(_ date: Date, calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date)
    }

    /// The welcome card of a valid Join.
    public static func welcome(_ form: ClubForm, calendar: Calendar = .current) -> String? {
        guard errors(form).isEmpty, let aisle = form.aisle, let date = form.deliveryDate else { return nil }
        let name = form.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let mail = form.email.trimmingCharacters(in: .whitespacesAndNewlines)
        return "Welcome, \(name). We'll write to \(mail) about the \(aisle.label) aisle and deliver on \(formatDate(date, calendar: calendar))."
    }
}
