# posthog-ios: lifecycle events go wrong after a late `optIn()`

When the app is already in the foreground when `optIn()` runs (as after any consent screen), `PostHogAppLifeCycleIntegration` starts as if the app were in the background. The first `Application Backgrounded` is never captured, and the next foreground is captured as `Application Opened` with `from_background: false`, so it counts as a cold launch. The same happens when `setup()` runs after launch. Later cycles are correct.

## Reproduction

macOS stands in for iOS here: the SDK maps `NSApplication.didResignActiveNotification` to its background callback and `didBecomeActiveNotification` to its active one, the same callbacks `UIApplication.didEnterBackgroundNotification` and `didBecomeActiveNotification` drive on iOS. The script posts those notifications itself and prints the lifecycle events `beforeSend` sees. Nothing is sent.

```sh
swift run -q Repro
```

Output with posthog-ios 3.93.1:

```
1. App is active. PostHog set up opted out, then the user opts in:
  captured: Application Installed
2. User sends the app to the background (expected: Application Backgrounded):
3. User brings it back (expected: Application Opened from_background=true):
  captured: Application Opened from_background=false
4. Background and foreground again:
  captured: Application Backgrounded
  captured: Application Opened from_background=true
```

## Expected

Step 2 captures `Application Backgrounded`, and step 3 captures `Application Opened` with `from_background: true`.

## Actual

Step 2 captures nothing, and step 3 captures `from_background: false`.

`optIn()` installs the integrations (`PostHogSDK.optIn()` → `installIntegrations()`), and `PostHogAppLifeCycleIntegration` starts with `isAppBackgrounded = true` and `isFreshAppLaunch = true` whatever the app's state is. The first `didEnterBackground` hits `guard !isAppBackgrounded` in `captureAppBackgrounded()` and is skipped, and the next `didBecomeActive` takes the fresh-launch branch in `captureAppOpened()`.

`AppLifecyclePublishing.isInBackground` exists for exactly this ("NotificationCenter doesn't replay past lifecycle events, so consumers that care about the value at subscription time should seed from this"), but the lifecycle integration doesn't seed from it.

A possible fix: seed `isAppBackgrounded` from `isInBackground` in `start()`, and when the app is already in the foreground there, treat the next open as one from the background.

## Environment

- posthog-ios 3.93.1 (Swift Package Manager)
- macOS 27.2, Xcode 27.2, Swift 6.4.2
- Also seen on iOS 27.2 (iPhone 17 simulator) in an app that calls `optIn()` once the user's consent loads.

Reported in https://github.com/PostHog/posthog-ios/issues/1002
