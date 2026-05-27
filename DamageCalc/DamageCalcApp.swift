import SwiftUI
import GoogleMobileAds
import AppTrackingTransparency

@main
struct DamageCalcApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(screenshotMode: CommandLine.arguments.contains("SCREENSHOT_MODE"))
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
