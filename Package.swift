// swift-tools-version:6.0
import PackageDescription

let package = Package(
  name: "Repro",
  platforms: [.macOS(.v13)],
  dependencies: [
    .package(url: "https://github.com/PostHog/posthog-ios", exact: "3.93.1")
  ],
  targets: [
    .executableTarget(name: "Repro", dependencies: [.product(name: "PostHog", package: "posthog-ios")])
  ]
)
