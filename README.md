# Swift Authentication JWT

[![Documentation](https://img.shields.io/badge/docc-read_documentation-blue)](https://swiftpackageindex.com/swift-microservices/swift-authentication-jwt/documentation)
[![Release](https://img.shields.io/github/v/release/swift-microservices/swift-authentication-jwt)](https://github.com/swift-microservices/swift-authentication-jwt/releases)
[![Swift versions](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fswift-microservices%2Fswift-authentication-jwt%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/swift-microservices/swift-authentication-jwt)
[![CI](https://github.com/swift-microservices/swift-authentication-jwt/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/swift-microservices/swift-authentication-jwt/actions/workflows/ci.yml)

Swift Authentication JWT makes a JSON Web Token your service's bearer credential: one process
issues tokens with a private key, and every other service proves them with the public key.

- 🔑 `JWTIssuer` and `JWTAuthenticator`, the two halves of a bearer token
- 🧩 Built on [swift-authentication](https://github.com/swift-microservices/swift-authentication)
  1.0 and [jwt-kit](https://github.com/vapor/jwt-kit) 5.7.1
- 📱 Runs on macOS 15 and Linux, including the static Linux SDK
- 🔧 Swift 6.3 and the Swift 6 language mode

🔗 Jump to:
- 📖 [Overview](#-overview)
- 🏁 [Getting Started](#-getting-started)
- 📘 [Documentation](#-documentation)
- 🧰 [Release Info](#-release-info)
- 🛠️ [Support](#%EF%B8%8F-support)

## 📖 Overview

A JSON Web Token is a payload signed with a private key. The one process that holds that key is
the issuer: it mints a token once a person has proved who they are some other way, such as a
password or a passkey. Every other process holds only the public key, so it can check a token
but never sign one.

This package gives those two roles a type each. `JWTIssuer<Payload>` is swift-authentication's
`CredentialIssuer<Payload, String>`: it signs a payload and returns the token.
`JWTAuthenticator<Payload>` is an `Authenticator<String, Payload>`: it takes the token as
presented and returns the verified payload, or throws if verification fails.

**Key Features:**
- 🧾 **Your token shape**: the payload is your own `JWTPayload` type. The package never reads
  your claims; it leaves which ones to enforce to the payload's own `verify(using:)`.
- ✅ **Signature, then claims**: the authenticator checks the signature first and then runs the
  payload's `verify(using:)`, so an expired token fails the same way a forged one does.
- 🔐 **Keys are your choice**: both types take a jwt-kit `JWTKeyCollection`, so which algorithms
  and how many keys is up to the application.
- 🔌 **Fits any transport**: because the types are swift-authentication's protocols, the
  [gRPC](https://github.com/swift-microservices/swift-authentication-grpc) and
  [Hummingbird](https://github.com/swift-microservices/swift-authentication-hummingbird) packages can read the
  token off a request and apply the authenticator.

Authentication proves an identity; it doesn't decide what that identity may do. Whether a call
requires a token, and what a verified user is allowed to do, stay the application's decisions.

## 🏁 Getting Started

### Prerequisites

- Swift 6.3 or later
- macOS 15 or later, or Linux

To install or upgrade Swift, see https://www.swift.org/install/.

### Adding as a dependency

Add the package to your `Package.swift`, along with jwt-kit for `JWTPayload` and the keys:

```swift
dependencies: [
    .package(url: "https://github.com/swift-microservices/swift-authentication-jwt.git", from: "1.0.0"),
    .package(url: "https://github.com/vapor/jwt-kit.git", from: "5.7.1"),
],
targets: [
    .target(
        name: "MyService",
        dependencies: [
            .product(name: "AuthenticationJWT", package: "swift-authentication-jwt"),
            .product(name: "JWTKit", package: "jwt-kit"),
        ]
    ),
]
```

### Usage

#### 1. Define your token's payload

The payload is your type. `AppToken` here is an example; put your own claims in it. Its
`verify(using:)` is where you enforce the claims that matter: at least the issuer, the audience
your service accepts, and the expiry.

```swift
import Foundation
import JWTKit

struct AppToken: JWTPayload {
    enum CodingKeys: String, CodingKey {
        case subject = "sub"
        case issuer = "iss"
        case audience = "aud"
        case expirationDate = "exp"
        case role
    }

    let subject: String
    let issuer: String
    let audience: String
    let expirationDate: Date
    let role: String

    // Runs after the signature verifies.
    func verify(using algorithm: some JWTAlgorithm) throws {
        try ExpirationClaim(value: expirationDate).verifyNotExpired()
        try AudienceClaim(value: [audience]).verifyIntendedAudience(includes: "posts")
        guard issuer == "https://auth.example.com" else {
            throw JWTError.claimVerificationFailure(failedClaim: IssuerClaim(value: issuer), reason: "unexpected issuer")
        }
    }
}
```

#### 2. Issue a token with the private key

Only the process that signs users in holds the private key. Put it in a `JWTKeyCollection` and
hand that to a `JWTIssuer`:

```swift
import AuthenticationJWT
import JWTKit

// A fresh Ed25519 key for the example. In production, load yours,
// for instance with `EdDSA.PrivateKey(pem:)`.
let privateKey = try EdDSA.PrivateKey(curve: .ed25519)

let signingKeys = JWTKeyCollection()
await signingKeys.add(eddsa: privateKey)
let issuer = JWTIssuer<AppToken>(keys: signingKeys)

// The compact token string to send back to the user.
let token = try await issuer.issue(
    for: AppToken(
        subject: "alice",
        issuer: "https://auth.example.com",
        audience: "posts",
        expirationDate: .now + 3600,
        role: "user"
    )
)
```

#### 3. Verify it with the public key

Every service that receives the token holds only the public key, and uses a `JWTAuthenticator`:

```swift
// In production, load it, for instance with `EdDSA.PublicKey(pem:)`.
let publicKey = privateKey.publicKey

let verificationKeys = JWTKeyCollection()
await verificationKeys.add(eddsa: publicKey)
let authenticator = JWTAuthenticator<AppToken>(keys: verificationKeys)

// Returns the verified payload. A bad signature, an expired token, or
// a wrong issuer or audience throws.
let claims = try await authenticator.authenticate(token)
print(claims.subject) // "alice"
```

A transport package such as swift-authentication-grpc reads the token off the call, applies the
authenticator, and binds the result as a `Principal<AppToken, String>`. A call with no token
never reaches the authenticator; requiring one is up to you.

#### Users across services

mTLS secures the connections between services; JWTs authenticate users. Each receiving service
verifies the original token's signature, issuer, audience, and expiry itself. Apply bearer
authentication to user routes and RPC descriptors, forward the original token only to upstream
user descriptors, and authorize the operation in the use case that owns it.

A token's payload is readable without any key: signing gives integrity, not confidentiality, so
don't put secrets in it. For key rotation and the reasoning behind these rules, see
[Tokens as credentials](https://swiftpackageindex.com/swift-microservices/swift-authentication-jwt/documentation/authenticationjwt/tokensascredentials).

## 📘 Documentation

- [API Documentation](https://swiftpackageindex.com/swift-microservices/swift-authentication-jwt/documentation)
  on Swift Package Index, with the full reference for `JWTIssuer` and `JWTAuthenticator`
- [Tokens as credentials](https://swiftpackageindex.com/swift-microservices/swift-authentication-jwt/documentation/authenticationjwt/tokensascredentials)
  — what a token proves, who holds which key, and why an invalid token is refused rather than
  ignored

Related packages:
- [swift-authentication](https://github.com/swift-microservices/swift-authentication) — the
  `Authenticator`, `CredentialIssuer` and `Principal` types this package implements
- [jwt-kit](https://github.com/vapor/jwt-kit) — keys, algorithms and claims

## 🧰 Release Info

- **Versioning**: follows [Semantic Versioning](https://semver.org). The public API is stable from
  1.0.0, and only a major release breaks it; CI checks every pull request for API breakage.
- **jwt-kit types**: the public API uses jwt-kit's `JWTPayload` and `JWTKeyCollection`, so a
  jwt-kit major release that changes them would mean a major release here too.
- **Release notes**: on [GitHub Releases](https://github.com/swift-microservices/swift-authentication-jwt/releases).
- **Supported Swift versions**: 6.3 and 6.4, which CI tests on Linux (x86_64 and aarch64)
  alongside nightly toolchains.

## 🛠️ Support

If you have a question or hit a problem,
[open an issue](https://github.com/swift-microservices/swift-authentication-jwt/issues).

Pull requests are welcome. Keep a change focused, prove new behaviour with a test, and label the
pull request with its semantic version impact.

### Development

```sh
swift test
swift-format lint --strict --recursive Sources Tests    # what the soundness check runs
```

## License

MIT. See [LICENSE](LICENSE).
