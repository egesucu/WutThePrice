import SwiftUI
import WidgetKit

struct ContentView: View {
    @Environment(\.scenePhase) private var phase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var input = NSDecimalNumber(decimal: CurrencyStore.amount).description(withLocale: Locale.current)
    @State private var snapshot = CurrencyStore.snapshot
    @State private var loading = false
    @State private var error: String?
    @FocusState private var editing: Bool
    private let green = Color(red: 0.69, green: 0.94, blue: 0.45)
    private var amount: Decimal? { Money.parse(input) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    HStack {
                        Image(systemName: "arrow.left.arrow.right.circle.fill").foregroundStyle(green)
                        Text("EURO IN LIRA").font(.caption.weight(.bold)).tracking(3)
                        Spacer()
                        Text("EUR → TRY").font(.caption.monospaced()).foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your euros.\nIn Turkish lira.").font(.system(size: 42, weight: .semibold, design: .rounded))
                        Text("A little perspective on your money.").foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 18) {
                        Text("AMOUNT TO TRACK").font(.caption.weight(.semibold)).tracking(2).foregroundStyle(.secondary)
                        HStack(alignment: .firstTextBaseline) {
                            Text("€").foregroundStyle(green)
                            TextField("100", text: $input).keyboardType(.decimalPad).focused($editing)
                                .accessibilityLabel("Euro amount")
                            Text("EUR").font(.subheadline).foregroundStyle(.secondary)
                        }.font(.system(size: 38, weight: .medium, design: .rounded))
                        if amount == nil {
                            Text("Enter an amount from 0 to 1 billion using your local decimal separator.")
                                .font(.caption).foregroundStyle(.orange)
                        }
                        Divider()
                        Text("TURKISH LIRA").font(.caption.weight(.semibold)).tracking(2).foregroundStyle(.secondary)
                        if let snapshot, let amount {
                            Text(Money.text(snapshot.converted(amount), currency: "TRY"))
                                .font(.system(size: 44, weight: .semibold, design: .rounded))
                                .minimumScaleFactor(0.4).lineLimit(1).foregroundStyle(green)
                                .contentTransition(.numericText(value: NSDecimalNumber(decimal: snapshot.converted(amount)).doubleValue))
                                .animation(reduceMotion ? nil : .snappy, value: snapshot.converted(amount))
                            Label(changeText(snapshot), systemImage: snapshot.direction < 0 ? "arrow.down.right" : snapshot.direction > 0 ? "arrow.up.right" : "equal")
                                .font(.caption).foregroundStyle(.secondary)
                        } else {
                            Text("—").font(.system(size: 44)).foregroundStyle(green)
                            Text(snapshot == nil ? String(localized: "Fetching the latest reference rate") : String(localized: "Enter a valid euro amount")).font(.caption).foregroundStyle(.secondary)
                        }
                    }.padding(24).background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 28))
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("REFERENCE RATE").font(.caption2.weight(.bold)).tracking(2).foregroundStyle(.secondary)
                            Text(snapshot.map { "€1 = \(Money.text($0.rate, currency: "TRY"))" } ?? String(localized: "Waiting for a rate"))
                                .font(.headline.monospacedDigit())
                        }
                        Spacer()
                        Button { Task { await refresh() } } label: {
                            if loading { ProgressView() } else { Image(systemName: "arrow.clockwise").font(.title3) }
                        }.buttonStyle(.bordered).tint(green).disabled(loading).accessibilityLabel("Refresh exchange rate")
                    }
                    if let error { Text(error).font(.callout).foregroundStyle(.orange) }
                    if let snapshot {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Rate dated \(rateDateText(snapshot.rateDate))")
                            Text("Last checked \(snapshot.checkedAt.formatted(date: .abbreviated, time: .shortened))")
                        }.font(.caption).foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Make room on your Home Screen", systemImage: "square.grid.2x2").font(.headline)
                        Text("Add the Euro in Lira widget. Touch and hold it, choose Edit Widget, then enter a euro amount. Leave it empty to follow the amount in this app.")
                        Text("The widget requests a check every 30 minutes; iOS decides when it runs. Reference rates update daily, with gaps on weekends and holidays. Bank and exchange-office prices may differ.")
                        Link("Rates by Frankfurter ↗", destination: URL(string: "https://frankfurter.dev")!).tint(green)
                    }.font(.footnote).foregroundStyle(.secondary)
                }.padding(24)
            }
            .background(Color(red: 0.055, green: 0.075, blue: 0.065))
            .toolbar { if editing { ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("Done") { editing = false } } } }
            .task { await refresh() }
            .onChange(of: phase) { _, phase in
                if phase == .active { Task { await refresh() } }
            }
            .onChange(of: input) { _, _ in
                guard let amount else { return }
                CurrencyStore.amount = amount
                WidgetCenter.shared.reloadTimelines(ofKind: CurrencyStore.widgetKind)
            }
        }.preferredColorScheme(.dark)
    }

    private func rateDateText(_ raw: String) -> String {
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.timeZone = TimeZone(secondsFromGMT: 0)
        parser.dateFormat = "yyyy-MM-dd"
        guard let date = parser.date(from: raw) else { return raw }
        return date.formatted(.dateTime.day().month(.abbreviated).year())
    }

    private func changeText(_ snapshot: RateSnapshot) -> String {
        guard let previous = snapshot.previousRate else { return String(localized: "Watching for the next rate change") }
        let delta = snapshot.rate - previous
        let change = "\(delta >= 0 ? "+" : "")\(Money.text(delta * (amount ?? 0), currency: "TRY"))"
        return String(localized: "\(change) since previous observed rate")
    }

    @MainActor private func refresh() async {
        guard !loading else { return }
        loading = true
        defer { loading = false }
        do {
            snapshot = try await RateService.fetch()
            error = nil
            WidgetCenter.shared.reloadTimelines(ofKind: CurrencyStore.widgetKind)
        } catch {
            self.error = snapshot == nil ? String(localized: "Couldn’t load the rate. Check your connection and try again.") : String(localized: "Couldn’t refresh. Showing the saved rate and its date.")
        }
    }
}
