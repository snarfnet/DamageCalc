import SwiftUI
import GoogleMobileAds
import AppTrackingTransparency

@main
struct DamageCalcApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(screenshotIndex: {
                let args = CommandLine.arguments
                if args.contains("SCREENSHOT_MODE_2") { return 2 }
                if args.contains("SCREENSHOT_MODE_3") { return 3 }
                if args.contains("SCREENSHOT_MODE") || args.contains("SCREENSHOT_MODE_1") { return 1 }
                return 0
            }())
                .onAppear {
                    guard !CommandLine.arguments.contains("SCREENSHOT_MODE") else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        ATTrackingManager.requestTrackingAuthorization { _ in
                            DispatchQueue.main.async {
                                GADMobileAds.sharedInstance().start(completionHandler: nil)
                            }
                        }
                    }
                }
        }
    }
}
