// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "SmartHitTest",
  platforms: [.iOS(.v11)],
  products: [.library(name: "SmartHitTest", targets: ["SmartHitTest"])],
  targets: [.target(name: "SmartHitTest")],
  swiftLanguageVersions: [.v5]
)
