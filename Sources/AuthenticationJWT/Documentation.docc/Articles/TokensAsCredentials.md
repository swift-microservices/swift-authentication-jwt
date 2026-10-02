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
to the new one.

## The payload is the identity

The authenticator returns the payload as the identity. What is in it is the application's
choice, and the package never reads it. User tokens carry claims such as subject, role, issuer,
audience, and expiration. The owning use case checks what the verified user may do.

The payload’s `verify(using:)` enforces the required claims. The authenticator calls it after
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
original token's signature, issuer, audience, and expiry. Scope bearer authentication and
propagation to user RPC descriptors, and authorize the operation in the owning use case.
