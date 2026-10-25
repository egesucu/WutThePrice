import Foundation

struct RateSnapshot: Codable, Sendable {
    let rate: Decimal
    let previousRate: Decimal?
    let rateDate: String
    let checkedAt: Date

    var direction: Int {
        guard let previousRate else { return 0 }
        return rate == previousRate ? 0 : (rate > previousRate ? 1 : -1)
    }

    func converted(_ amount: Decimal) -> Decimal { amount * rate }
}

enum CurrencyStore {
    static let group = "group.tr.com.egesucu.wuttheprice"
    static let widgetKind = "EuroInLira"
    static var defaults: UserDefaults { UserDefaults(suiteName: group) ?? .standard }
    static var amount: Decimal {
        get { Decimal(string: defaults.string(forKey: "amount") ?? "100", locale: Locale(identifier: "en_US_POSIX")) ?? 100 }
        set { defaults.set(NSDecimalNumber(decimal: newValue).stringValue, forKey: "amount") }
    }
    static var snapshot: RateSnapshot? {
        get {
            guard let data = defaults.data(forKey: "rate") else { return nil }
            return try? JSONDecoder().decode(RateSnapshot.self, from: data)
        }
        set {
            if let newValue, let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: "rate")
            }
        }
    }
}

enum RateService {
    struct Response: Decodable {
        let date: String
        let base: String
        let quote: String
        let rate: Decimal
    }

    static func fetch() async throws -> RateSnapshot {
        let url = URL(string: "https://api.frankfurter.dev/v2/rate/EUR/TRY")!
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let result = try JSONDecoder().decode(Response.self, from: data)
        guard result.base == "EUR", result.quote == "TRY", result.rate > 0,
              NSDecimalNumber(decimal: result.rate).doubleValue.isFinite else {
            throw URLError(.cannotParseResponse)
        }
        let old = CurrencyStore.snapshot
        let snapshot = RateSnapshot(rate: result.rate,
                                    previousRate: old?.rate == result.rate ? old?.previousRate : old?.rate,
                                    rateDate: result.date, checkedAt: .now)
        CurrencyStore.snapshot = snapshot
        return snapshot
    }
}

enum Money {
    static func text(_ amount: Decimal, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "—"
    }
    static func parse(_ text: String) -> Decimal? {
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .decimal
        formatter.generatesDecimalNumbers = true
        // Reject partial parses such as “12abc”. Keyboard input uses the locale's separator.
        let separator = formatter.decimalSeparator ?? "."
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = normalized.components(separatedBy: separator)
        guard parts.count <= 2, normalized.contains(where: { $0.isNumber }),
              parts.allSatisfy({ $0.allSatisfy({ $0.isASCII && $0.isNumber }) }),
              let value = Decimal(string: parts.joined(separator: "."), locale: Locale(identifier: "en_US_POSIX")),
              value >= 0, value <= 1_000_000_000 else { return nil }
        return value
    }
}
