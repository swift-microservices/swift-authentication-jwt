// swift-tools-version: 6.3
import PackageDescription

let swiftSettings: [SwiftSetting] = [
    // https://github.com/apple/swift-evolution/blob/main/proposals/0335-existential-any.md
    .enableUpcomingFeature("ExistentialAny"),

    // https://github.com/swiftlang/swift-evolution/blob/main/proposals/0444-member-import-visibility.md
    .enableUpcomingFeature("MemberImportVisibility"),

    // https://github.com/swiftlang/swift-evolution/blob/main/proposals/0409-access-level-on-imports.md
    .enableUpcomingFeature("InternalImportsByDefault"),

    // https://github.com/swiftlang/swift-evolution/blob/main/proposals/0461-async-function-isolation.md
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
]

let package = Package(
    name: "swift-authentication-jwt",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "AuthenticationJWT",
            targets: ["AuthenticationJWT"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swift-microservices/swift-authentication.git", from: "0.1.0"),
        .package(url: "https://github.com/vapor/jwt-kit.git", from: "5.7.1"),
    ],
    targets: [
        .target(
            name: "AuthenticationJWT",
            dependencies: [
                .product(name: "Authentication", package: "swift-authentication"),
                .product(name: "JWTKit", package: "jwt-kit"),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "AuthenticationJWTTests",
            dependencies: [
                .target(name: "AuthenticationJWT"),
                .product(name: "Authentication", package: "swift-authentication"),
                .product(name: "JWTKit", package: "jwt-kit"),
            ],
            swiftSettings: swiftSettings
        ),
    ],
    swiftLanguageModes: [.v6]
)
