# Repository guidelines

This package proves bearer tokens that are JSON Web Tokens. Read this before changing anything.

## What this package is

- One product, `AuthenticationJWT`: `JWTIssuer`, a `CredentialIssuer<Payload, String>`, and
  `JWTAuthenticator`, an `Authenticator<String, Payload>`, both from swift-authentication, over
  jwt-kit.
- The payload is the application's `JWTPayload`. This package never reads claims; the payload's
  own `verify(using:)` decides which to enforce.
- The authenticator refuses by throwing and never declines. An invalid token is an error, not a
  credential this service happens not to admit.
- jwt-kit is pinned below 5.7.0 for the reason in `Package.swift`. Do not lift the pin without
  confirming the Xcode build.

## What does not belong here

- Reading claims, roles, or permissions.
- Anything about where a token travels. Transports read the `Authorization` value with their own
  framework's types and bind the principal themselves.
- Other token formats. A different format is a different package.

## Swift

- Swift 6.3, strict concurrency, `Sendable` everywhere it is meaningful.
- Tests use Swift Testing with keys generated in memory: issue-and-authenticate round trip,
  expired, foreign key, tampered, and the proved token bound as a principal.
- Doc comments on every public declaration; the DocC catalog is the long-form explanation.
- Format with `swift-format format --in-place --recursive Sources Tests`; the soundness check on
  every pull request runs the same rules, an API breakage check against the base branch, and
  shellcheck and yamllint.
- File headers follow the existing files: name, package, author, date.

## Releases

- Every pull request carries exactly one label: `⚠️ semver/major`, `🆕 semver/minor`,
  `🔨 semver/patch`, or `semver/none`. The label check blocks merging without one.
- Releases are GitHub Releases, created by the Auto Release workflow: run it by hand on `main`
  and it computes the next version from the labels of the pull requests merged since the last
  release, tags it, and writes the notes from `.github/release.yml`. A major bump is refused
  there and is cut by hand.
- Consumers pin by tag, never by branch or path.
