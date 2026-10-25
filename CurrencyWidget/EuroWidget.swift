import AppIntents
import SwiftUI
import WidgetKit

struct TrackEuroIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Track euros"
    static let description = IntentDescription("Choose an amount in EUR, or leave it empty to use the app amount.")
    @Parameter(title: "EUR amount", description: "Leave empty to follow the app. Use your device’s decimal separator.")
    var euroAmount: String?
}

struct EuroEntry: TimelineEntry {
    let date: Date
    let amount: Decimal
    let snapshot: RateSnapshot?
    var failed = false
    var invalidAmount = false
}

struct EuroProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> EuroEntry {
        EuroEntry(date: .now, amount: 100, snapshot: RateSnapshot(rate: 50, previousRate: 49.9, rateDate: "Preview", checkedAt: .now))
    }

    func snapshot(for configuration: TrackEuroIntent, in context: Context) async -> EuroEntry {
        if context.isPreview { return placeholder(in: context) }
        return entry(configuration, snapshot: CurrencyStore.snapshot)
    }

    func timeline(for configuration: TrackEuroIntent, in context: Context) async -> Timeline<EuroEntry> {
        let snapshot: RateSnapshot?
        var failed = false
        do { snapshot = try await RateService.fetch() }
        catch { snapshot = CurrencyStore.snapshot; failed = true }
        var value = entry(configuration, snapshot: snapshot)
        value.failed = failed
        return Timeline(entries: [value], policy: .after(Date.now.addingTimeInterval(30 * 60)))
    }

    private func entry(_ configuration: TrackEuroIntent, snapshot: RateSnapshot?) -> EuroEntry {
        let text = configuration.euroAmount?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let parsed = Money.parse(text)
        return EuroEntry(date: .now, amount: text.isEmpty ? CurrencyStore.amount : (parsed ?? 0),
                         snapshot: snapshot, invalidAmount: !text.isEmpty && parsed == nil)
    }
}

struct EuroWidgetView: View {
    let entry: EuroEntry
    @Environment(\.widgetFamily) private var family
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let green = Color(red: 0.69, green: 0.94, blue: 0.45)
    var body: some View {
        Group {
            if entry.invalidAmount {
                Text("—")
                    .accessibilityLabel("Invalid euro amount. Edit the widget to correct it.")
            } else if let snapshot = entry.snapshot {
                let value = snapshot.converted(entry.amount)
                Text(value, format: .number.precision(.fractionLength(2)))
                    .contentTransition(.numericText(value: NSDecimalNumber(decimal: value).doubleValue))
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.8), value: value)
                    .accessibilityLabel(entry.failed ? String(localized: "\(Money.text(value, currency: "TRY")), saved rate") : Money.text(value, currency: "TRY"))
            } else {
                Text("—")
                    .accessibilityLabel("Exchange rate unavailable. Open the app to try again.")
            }
        }
        .font(.system(size: family == .systemSmall ? 36 : 52, weight: .semibold, design: .rounded))
        .foregroundStyle(green)
        .lineLimit(1)
        .minimumScaleFactor(0.2)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(Color(red: 0.055, green: 0.075, blue: 0.065), for: .widget)
    }

}

@main
struct EuroWidget: Widget {
    let kind = CurrencyStore.widgetKind
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: TrackEuroIntent.self, provider: EuroProvider()) { entry in
            EuroWidgetView(entry: entry)
        }
        .configurationDisplayName("Euro in Lira")
        .description("Your euro amount, converted to Turkish lira using daily reference rates.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
