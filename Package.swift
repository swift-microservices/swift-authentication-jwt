// swift-tools-version: 6.3
import PackageDescription

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
            ]
        ),
        .testTarget(
            name: "AuthenticationJWTTests",
            dependencies: [
                .target(name: "AuthenticationJWT"),
                .product(name: "Authentication", package: "swift-authentication"),
                .product(name: "JWTKit", package: "jwt-kit"),
            ]
        ),
    ]
)
