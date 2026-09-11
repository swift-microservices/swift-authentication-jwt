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
        // Below 5.7.0 on purpose: 5.7.0 compiles with `treatAllWarnings(as: .error)`, and Xcode
        // passes `-suppress-warnings` to every dependency, which the compiler refuses to combine.
        // `swift build` passes on 5.7.0; the Xcode build fails in the JWTKit target.
        .package(url: "https://github.com/vapor/jwt-kit.git", "5.3.0"..<"5.7.0"),
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
