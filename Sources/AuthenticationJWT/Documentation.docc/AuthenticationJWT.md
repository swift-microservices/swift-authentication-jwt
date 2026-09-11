# ``AuthenticationJWT``

A bearer token as a JSON Web Token: issued with a private key, proved with the public one.

## Overview

``JWTIssuer`` is a `CredentialIssuer<Payload, String>` and ``JWTAuthenticator`` is an
`Authenticator<String, Payload>`, both from swift-authentication, over jwt-kit. The credential is
the token string a transport reads from an `Authorization` header or metadata; the identity is
the payload the token carries.

The payload is the application's type. This package asks only that it be a `JWTPayload`, and
leaves which claims to enforce to the payload's own `verify(using:)`. Whether it names a person
or a process is a claim inside it.

A token that does not verify is refused, never declined: an invalid credential is an error the
caller must see, while a valid one this service does not admit would be the transport's or the
handler's decision.

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
