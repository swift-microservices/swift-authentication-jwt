# Tokens as credentials

What a token proves, who holds which key, and why an invalid token is refused rather than
ignored.

## One issuer, many authenticators

A JSON Web Token is a payload signed by a private key. The one process that holds that key is
the issuer: it mints a token when someone proves who they are by other means, a password, a
passkey, a service credential. Every other process holds only the public key, and can prove a
token it is handed without being able to mint one. That asymmetry is the whole design: a stolen
verification key lets an attacker read tokens, never forge them.

``JWTIssuer`` and ``JWTAuthenticator`` are those two roles, over a `JWTKeyCollection` each.
Which algorithms and how many keys is the application's choice, and a collection with two keys
is how rotation works: the authenticator accepts tokens signed by either while the issuer moves
to the new one.

## The payload is the identity

The authenticator returns the payload as the identity. What is in it is the application's
choice, and the package never reads it. A subject, a role, an expiration are the usual claims;
whether the subject is a person or a process is one more claim, or the absence of one. Roles
travel in the token and the application decides what they permit.

Which claims to enforce is the payload's own `verify(using:)`. The authenticator calls it after
the signature checks, so an expired token fails the same way a forged one does.

## Refused, never declined

An `Authenticator` may decline a credential with `nil`, meaning it names nobody this service
recognises, and the call continues unbound. A JWT authenticator never does that. A token that
does not verify, a bad signature, an expired claim, an unknown issuer, is not a valid credential
this service happens not to admit; it is an invalid one, and the caller must be told. The
authenticator throws, and the transport turns that into its unauthenticated status.

A token that verifies but names a subject the service does not know is a different question,
and not this package's: the handler decides what a proven identity may do.
