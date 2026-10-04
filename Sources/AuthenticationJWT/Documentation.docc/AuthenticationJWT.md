# ``AuthenticationJWT``

A bearer token as a JSON Web Token: issued with a private key, proved with the public one.

## Overview

``JWTIssuer`` is a `CredentialIssuer<Payload, String>` and ``JWTAuthenticator`` is an
`Authenticator<String, Payload>`, both from swift-authentication, over jwt-kit. The credential is
the token string a transport reads from an `Authorization` header or metadata; the identity is
the payload the token carries.

The payload is the application's type. This package asks only that it be a `JWTPayload`, and
leaves which claims to enforce to the payload's own `verify(using:)`: the issuer, the audience,
and the expiry at least.

Authentication returns the verified payload or throws when verification fails. Whether a call
requires an identity, and what an authenticated identity may do, are the application's
decisions.

## User authentication

mTLS secures service connections. Each receiving service authenticates users by verifying the
original JWT's signature and required claims. Apply bearer authentication to user routes
and RPC descriptors, and check user permissions in the owning use case.

## Example

```swift
struct AppToken: JWTPayload {
    enum CodingKeys: String, CodingKey {
        case subject = "sub"
        case issuer = "iss"
        case audience = "aud"
        case expiration = "exp"
        case role
    }

    let subject: SubjectClaim
    let issuer: IssuerClaim
    let audience: AudienceClaim
    let expiration: ExpirationClaim
    let role: String

    func verify(using algorithm: some JWTAlgorithm) throws {
        try expiration.verifyNotExpired()
        try audience.verifyIntendedAudience(includes: "posts")
        guard issuer.value == "https://auth.example.com" else {
            throw JWTError.claimVerificationFailure(failedClaim: issuer, reason: "unexpected issuer")
        }
    }
}

let signingKeys = JWTKeyCollection()
await signingKeys.add(eddsa: privateKey)
let issuer = JWTIssuer<AppToken>(keys: signingKeys)

let verificationKeys = JWTKeyCollection()
await verificationKeys.add(eddsa: publicKey)
let authenticator = JWTAuthenticator<AppToken>(keys: verificationKeys)

let token = try await issuer.issue(
    for: AppToken(
        subject: "alice",
        issuer: "https://auth.example.com",
        audience: "posts",
        expiration: .init(value: .now + 3600),
        role: "user"
    )
)
let claims = try await authenticator.authenticate(token)
```

## Topics

### Issuing and proving

- ``JWTIssuer``
- ``JWTAuthenticator``

### Design

- <doc:TokensAsCredentials>
