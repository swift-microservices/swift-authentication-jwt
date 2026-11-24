# Tokens as credentials

What a token proves, who holds which key, and why an invalid token is refused rather than
ignored.

## One issuer, many authenticators

A JSON Web Token is a payload signed by a private key. The one process that holds that key is
the issuer: it mints a token when a person proves who they are by other means, a password or a
passkey. Every other process holds only the public key, and can verify a
token without being able to sign one. JWT payloads are readable without the verification key;
signing provides integrity, not confidentiality.

``JWTIssuer`` and ``JWTAuthenticator`` are those two roles, over a `JWTKeyCollection` each.
Which algorithms and how many keys is the application's choice, and a collection with two keys
is how rotation works: the authenticator accepts tokens signed by either while the issuer moves
to the new one. Add each key with its own `kid` (`keys.add(eddsa: publicKey, kid: "2026-11")`),
because a collection keeps only one key without one. Give the issuer the same `kid`
(`JWTIssuer(keys: keys, kid: "2026-11")`) and each token names it in its header. The
authenticator tries the key a token's `kid` names, or the default key, and then every other key
in the collection.

## Rotating a key

A key changes in three steps, so no authenticator meets a token it can't check:

1. Add the new public key, under its own `kid`, to every authenticator's collection beside the
   old one, and deploy every service that authenticates.
2. Move the issuer to the new key: add the new private key under its `kid` and pass that `kid`
   to ``JWTIssuer/init(keys:kid:)``. Its tokens now name the new key.
3. Once the longest-lived token signed with the old key has expired, remove the old public key
   from every collection.

```swift
// Step 1, on every service that authenticates.
let verificationKeys = JWTKeyCollection()
await verificationKeys.add(eddsa: oldPublicKey, kid: "2026-05")
await verificationKeys.add(eddsa: newPublicKey, kid: "2026-11")
let authenticator = JWTAuthenticator<AppToken>(keys: verificationKeys)

// Step 2, on the issuer.
let signingKeys = JWTKeyCollection()
await signingKeys.add(eddsa: newPrivateKey, kid: "2026-11")
let issuer = JWTIssuer<AppToken>(keys: signingKeys, kid: "2026-11")
```

Without a `kid`, the issuer signs with its collection's default key and its tokens name none;
the authenticator then tries its default key and every other key in turn.

## The payload is the identity

The authenticator returns the payload as the identity. What is in it is the application's
choice, and the package never reads it. User tokens carry claims such as subject, role, issuer,
audience, and expiration. The owning use case checks what the verified user may do.

The payload's `verify(using:)` enforces the required claims: at least the issuer, the audience
the service accepts, and the expiry. The authenticator calls it after
the signature checks, so an expired token fails the same way a forged one does.

## Authentication returns an identity or throws

The authenticator returns the payload after the signature and the payload's claims verify.
Authentication throws if either check fails. The supplied transport packages translate that
failure into their unauthenticated status. A call with no token never reaches the authenticator;
requiring an identity is the application's decision.

A token that verifies but names a subject the service does not know is a different question,
and not this package's: the owning use case checks the user and resource relationships.

## User authentication

mTLS secures service connections; JWTs authenticate users. Each receiving service verifies the
original token's signature, issuer, audience, and expiry. Apply bearer authentication to user
routes and RPC descriptors, forward the original token only to upstream user descriptors, and
authorize the operation in the owning use case.
