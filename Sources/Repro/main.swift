import AppKit
import Foundation
import PostHog

// The app is already in the foreground when the user consents, as after any consent screen.
let center = NotificationCenter.default
func becomeActive() { center.post(name: NSApplication.didBecomeActiveNotification, object: nil) }
func goToBackground() { center.post(name: NSApplication.didResignActiveNotification, object: nil) }

let config = PostHogConfig(projectToken: "phc_repro", host: "http://127.0.0.1:9")
config.optOut = true
config.preloadFeatureFlags = false
config.captureScreenViews = false
config.setBeforeSend { event in
  if event.event.hasPrefix("Application") {
    let fromBackground = event.properties["from_background"].map { " from_background=\($0)" } ?? ""
    print("  captured: \(event.event)\(fromBackground)")
  }
  return nil
}

becomeActive()
print("1. App is active. PostHog set up opted out, then the user opts in:")
PostHogSDK.shared.setup(config)
PostHogSDK.shared.optIn()

print("2. User sends the app to the background (expected: Application Backgrounded):")
goToBackground()

print("3. User brings it back (expected: Application Opened from_background=true):")
becomeActive()

print("4. Background and foreground again:")
goToBackground()
becomeActive()

// Let the SDK's queues drain before exiting.
RunLoop.main.run(until: Date().addingTimeInterval(1))
