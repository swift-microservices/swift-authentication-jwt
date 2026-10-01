# swift-authentication-jwt

A bearer token as a JSON Web Token: issued with a private key, proved with the public one.

```swift
.package(url: "https://github.com/swift-microservices/swift-authentication-jwt.git", from: "0.3.0"),
```

```swift
.product(name: "AuthenticationJWT", package: "swift-authentication-jwt"),
```

## The types

| Type | Role |
| --- | --- |
| `JWTIssuer<Payload>` | a `CredentialIssuer<Payload, String>`: mints the token; the one process holding the private key |
| `JWTAuthenticator<Payload>` | an `Authenticator<String, Payload>`: returns the verified payload or throws if authentication fails |

Both come from [swift-authentication](https://github.com/swift-microservices/swift-authentication)'s
shape and are built on [jwt-kit](https://github.com/vapor/jwt-kit). Each takes a
`JWTKeyCollection`, so which algorithms and how many keys is the application's choice.

## The token shape is yours

The package never reads your claims. It asks only for a `JWTPayload`, and leaves which claims to
enforce to the payload's own `verify(using:)`:

```swift
struct AppToken: JWTPayload {
    let subject: SubjectClaim
    let role: String
    let expiration: ExpirationClaim

    func verify(using algorithm: some JWTAlgorithm) throws {
        try expiration.verifyNotExpired()
    }
}
```

```swift
let signingKeys = JWTKeyCollection()
await signingKeys.add(eddsa: privateKey)
let issuer = JWTIssuer<AppToken>(keys: signingKeys)

let verificationKeys = JWTKeyCollection()
await verificationKeys.add(eddsa: publicKey)
let authenticator = JWTAuthenticator<AppToken>(keys: verificationKeys)

let token = try await issuer.issue(for: AppToken(subject: "alice", role: "user", expiration: .init(value: .now + 3600)))
let claims = try await authenticator.authenticate(token)
```

Authentication returns the verified payload. A token that fails verification, such as one with
a bad signature or an expired claim, throws. A transport package such as
swift-authentication-grpc reads the token off the call, applies the authenticator, and binds the
result as a `Principal<AppToken, String>`. Requiring an identity and deciding what it may do are
the application's decisions.

## User authentication

mTLS secures service connections; JWTs authenticate users. Each receiving service verifies the
original token's signature, issuer, audience, and expiry. Scope bearer authentication and
propagation to user RPC descriptors, and authorize the operation in the owning use case.

## Requirements

Swift 6.3, macOS 15 or Linux. jwt-kit 5.7.1 or later.

## Development

```sh
swift test
swift-format lint --strict --recursive Sources Tests    # what the soundness check runs
```

## Contributing

Pull requests are welcome. Keep a change focused, prove new behaviour with a test, and label the
pull request with its semantic version impact.

## License

MIT. See [LICENSE](LICENSE).
