# ``AuthenticationJWT``

A bearer token as a JSON Web Token: issued with a private key, proved with the public one.

## Overview

``JWTIssuer`` is a `CredentialIssuer<Payload, String>` and ``JWTAuthenticator`` is an
`Authenticator<String, Payload>`, both from swift-authentication, over jwt-kit. The credential is
the token string a transport reads from an `Authorization` header or metadata; the identity is
the payload the token carries.

The payload is the application's type. This package asks only that it be a `JWTPayload`, and
leaves which claims to enforce to the payload's own `verify(using:)`.

Authentication returns the verified payload or throws when verification fails. Whether a call
requires an identity, and what an authenticated identity may do, are the application's
decisions.

## User authentication

mTLS secures service connections. Each receiving service authenticates users by verifying the
original JWT's signature and required claims. Apply bearer authentication to user RPC
descriptors and check user permissions in the owning use case.

## Example

```swift
struct AppToken: JWTPayload {
    let subject: SubjectClaim
    let role: String
    let expiration: ExpirationClaim

    func verify(using algorithm: some JWTAlgorithm) throws {
        try expiration.verifyNotExpired()
    }
}

let signingKeys = JWTKeyCollection()
await signingKeys.add(eddsa: privateKey)
let issuer = JWTIssuer<AppToken>(keys: signingKeys)

let verificationKeys = JWTKeyCollection()
await verificationKeys.add(eddsa: publicKey)
let authenticator = JWTAuthenticator<AppToken>(keys: verificationKeys)

let token = try await issuer.issue(for: AppToken(subject: "alice", role: "user", expiration: .init(value: .now + 3600)))
let claims = try await authenticator.authenticate(token)
```

## Topics

### Issuing and proving

- ``JWTIssuer``
- ``JWTAuthenticator``

### Design

- <doc:TokensAsCredentials>
