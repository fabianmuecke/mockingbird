// swift-tools-version:5.2
import class Foundation.ProcessInfo
import PackageDescription

/// The manifest is split into several sub-packages based on build type. It's a slight hack, but
/// does offer a few advantages until SPM evolves, such as no package dependencies when consuming
/// just the framework product, target-specific platform requirements, and SwiftUI compatibility.
let package: Package =

  // MARK: Framework

  .init(
    name: "Mockingbird",
    platforms: [
      .macOS(.v10_15),
      .iOS(.v9),
      .tvOS(.v9),
      .watchOS("7.4"),
    ],
    products: [
      .library(name: "Mockingbird", targets: ["Mockingbird", "MockingbirdObjC"]),
    ],
    targets: [
      .target(
        name: "Mockingbird",
        dependencies: ["MockingbirdBridge", "MockingbirdCommon"],
        path: "Sources",
        exclude: ["MockingbirdFramework/Objective-C"],
        sources: ["MockingbirdFramework"],
        swiftSettings: [.define("MKB_SWIFTPM")],
        linkerSettings: [.linkedFramework("XCTest")]
      ),
      .target(
        name: "MockingbirdObjC",
        dependencies: ["Mockingbird", "MockingbirdBridge"],
        path: "Sources/MockingbirdFramework/Objective-C",
        exclude: ["Bridge"],
        cSettings: [.headerSearchPath("./"), .define("MKB_SWIFTPM")]
      ),
      .target(
        name: "MockingbirdBridge",
        path: "Sources/MockingbirdFramework/Objective-C/Bridge",
        cSettings: [.headerSearchPath("include"), .define("MKB_SWIFTPM")]
      ),
      .target(name: "MockingbirdCommon"),
    ]
  )
if ProcessInfo.processInfo.environment["MKB_BUILD_EXECUTABLES"] == "1" {
  // MARK: Executables

  package.products += [
    .executable(name: "mockingbird", targets: ["MockingbirdCli"]),
    .executable(name: "automation", targets: ["MockingbirdAutomationCli"]),
  ]
  package.dependencies += [
    .package(url: "https://github.com/apple/swift-argument-parser.git", .exact("1.0.2")),
    .package(url: "https://github.com/kylef/PathKit.git", .exact("1.0.1")),
    .package(
      name: "SwiftSyntax",
      url: "https://github.com/apple/swift-syntax.git",
      .exact("0.50600.1")
    ),
    .package(url: "https://github.com/jpsim/SourceKitten.git", .exact("0.32.0")),
    .package(url: "https://github.com/tuist/XcodeProj.git", .exact("8.7.1")),
    .package(url: "https://github.com/weichsel/ZIPFoundation.git", .exact("0.9.14")),
  ]
  package.targets += [
    .target(
      name: "MockingbirdCli",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        "MockingbirdCommon",
        "MockingbirdGenerator",
        "XcodeProj",
        "ZIPFoundation",
      ],
      linkerSettings: [
        .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path"]),
        .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/Libraries"]),
      ]
    ),
    .target(
      name: "MockingbirdGenerator",
      dependencies: [
        .product(name: "SourceKittenFramework", package: "SourceKitten"),
        "MockingbirdCommon",
        "SwiftSyntax",
        .product(name: "SwiftSyntaxParser", package: "SwiftSyntax"),
        "XcodeProj",
      ]
    ),
    .target(
      name: "MockingbirdAutomationCli",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        "MockingbirdAutomation",
        "MockingbirdCommon",
        "PathKit",
      ]
    ),
    .target(
      name: "MockingbirdAutomation",
      dependencies: [
        "MockingbirdCommon",
        "PathKit",
      ]
    ),
    .testTarget(
      name: "MockingbirdAutomationTests",
      dependencies: ["MockingbirdAutomation"]
    ),
  ]
}

extension Package {
  func merge(with other: Package) {
    if let platforms = self.platforms {
      if let other = other.platforms {
        self.platforms = platforms + other
      }
    } else {
      self.platforms = other.platforms
    }
    self.dependencies += other.dependencies
    self.products += other.products
    self.targets += other.targets
  }
}
