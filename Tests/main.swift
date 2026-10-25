import Foundation

func check(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

let snapshot = RateSnapshot(rate: Decimal(string: "40.1234")!, previousRate: 40, rateDate: "2026-10-23", checkedAt: .now)
check(snapshot.converted(Decimal(string: "123.45")!) == Decimal(string: "4953.23373")!, "Decimal conversion must retain precision")
check(snapshot.direction == 1, "Rising rate")
check(RateSnapshot(rate: 39, previousRate: 40, rateDate: "", checkedAt: .now).direction == -1, "Falling rate")
check(RateSnapshot(rate: 40, previousRate: 40, rateDate: "", checkedAt: .now).direction == 0, "Unchanged rate")
check(Money.parse("0") == 0, "Zero is valid")
for invalid in ["", "-1", "12abc", "NaN", "1e3", "1000000001", "1..2"] {
    check(Money.parse(invalid) == nil, "Invalid input: \(invalid)")
}
let separator = Locale.current.decimalSeparator ?? "."
check(Money.parse("123\(separator)45") == Decimal(string: "123.45"), "Locale decimal entry")
let response = try JSONDecoder().decode(RateService.Response.self, from: Data(#"{"date":"2026-10-23","base":"EUR","quote":"TRY","rate":40.1234}"#.utf8))
check(response.rate == snapshot.rate, "API decimal decoding")
let cached = try JSONDecoder().decode(RateSnapshot.self, from: JSONEncoder().encode(snapshot))
check(cached.rate == snapshot.rate && cached.previousRate == snapshot.previousRate, "Cache round trip")
print("All currency checks passed")
