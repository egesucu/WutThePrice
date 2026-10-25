# Euro in Lira

A Swift 6 / SwiftUI iOS 17+ app with small and medium configurable WidgetKit widgets.

Open `WTP.xcodeproj`, select WTP, then run on an iPhone. The app and widget use the App Group `group.tr.com.egesucu.wuttheprice`; enable that group for both identifiers in your Apple Developer account when running on a physical device. The current signing team is retained from the original project.

Enter an EUR amount in the app. Add **Euro in Lira** to your Home Screen, hold the widget and choose **Edit Widget**. Enter an independent EUR amount, or leave the field blank to follow the app. Numbers use your device’s decimal separator. Invalid widget input displays an instruction instead of silently tracking another amount.

## Rates and refreshes

The app requests `https://api.frankfurter.dev/v2/rate/EUR/TRY`. Frankfurter is free without a key and blends daily reference rates from official sources. These are not real-time executable bank buy/sell quotes. The published rate date and last successful app check are displayed separately. On network failure the last successful quote remains visible and is labeled as saved.

The widget requests another timeline after 30 minutes, subject to iOS scheduling. Opening or refreshing the app also requests a widget reload. Numeric transitions use SwiftUI’s numeric content transition with a sub-second animation and respect Reduce Motion. Widget animation and refresh timing ultimately depend on the OS, including Always-On display behavior. First load and unchanged values do not animate.

Amounts and quotes stay in local App Group storage. Only the currency pair is sent to the API, never your tracked amount. Conversions use Decimal arithmetic, rounded only for display.

## Project maintenance

`project.yml` is the XcodeGen project specification. After changing target configuration, run `xcodegen generate`. Swift 6 is enabled for both targets. The original Xcode 27 project definition is preserved in `ProjectBackup/original-project.xcproj`, outside the active project to avoid competing project definitions.

Currency checks:

```sh
swiftc -swift-version 6 Shared/ExchangeRate.swift Tests/main.swift -o /tmp/WTP-currency-tests
/tmp/WTP-currency-tests
```

Build:

```sh
xcodebuild -project WTP.xcodeproj -scheme WTP -sdk iphonesimulator -derivedDataPath /tmp/WTP-build CODE_SIGNING_ALLOWED=NO build
```

Documentation: https://frankfurter.dev/tr/

## Personal iPhone installation

The project targets iPhone and uses development signing for direct installation with Xcode. Select your connected iPhone and run WTP; no App Store or TestFlight distribution is required. Keep the same bundle identifiers and App Group when updating to retain your saved amount. Development installations remain subject to the signing profile’s expiry and may need to be rebuilt later.

The icon source is `Design/GenerateIcon.swift`, rendered using AppKit to the AppIcon asset. Regenerate it on macOS with:

```sh
swift Design/GenerateIcon.swift WTP/Assets.xcassets/AppIcon.appiconset/AppIcon.png
```

## Languages

English and Turkish are bundled in both app and widget, including widget configuration and accessibility text. iOS selects the language from the user's preferences; the app display name is **Euro Kaç Lira** in Turkish. Select Turkish under the app's Language setting to override the system preference. Number and date formatting follows the device region.
