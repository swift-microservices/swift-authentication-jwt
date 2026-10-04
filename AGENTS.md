# Repository guidelines

This package proves bearer tokens that are JSON Web Tokens. Read this before changing anything.

## What this package is

- One product, `AuthenticationJWT`: `JWTIssuer`, a `CredentialIssuer<Payload, String>`, and
  `JWTAuthenticator`, an `Authenticator<String, Payload>`, both from swift-authentication, over
  jwt-kit.
- The payload is the application's `JWTPayload`. This package never reads claims; the payload's
  own `verify(using:)` decides which to enforce.
- The authenticator returns the verified payload or throws if authentication fails. The
  application decides whether a call requires an identity and what that identity may do.
- jwt-kit is required from 5.7.1, the first release whose warnings-as-errors setting no longer
  reaches an Xcode build. Do not lower the floor below it.

## Application standard

- mTLS secures backend connections. JWTs authenticate users; each receiving service verifies
  the original token's signature, issuer, audience, and expiry.
- Apply bearer authentication to user routes and RPC descriptors, and forward the original
  token only to upstream user descriptors. User handlers require the
  identity, and owning use cases authorize the operation.

## What does not belong here

- Reading claims, roles, or permissions.
- Anything about where a token travels. Transports read the `Authorization` value with their own
  framework's types and bind the principal themselves.
- Other token formats. A different format is a different package.

## Swift

- Swift 6.3, strict concurrency, `Sendable` everywhere it is meaningful.
- Tests use Swift Testing with keys generated in memory: issue-and-authenticate round trip,
  expired, wrong audience, wrong issuer, foreign key, tampered, and the proved payload and token
  forming a principal.
- Doc comments on every public declaration; the DocC catalog is the long-form explanation.
- Use the checked-in `.swift-format`, copied exactly from apple/swift-temporal-sdk at
  `508797b5468dbc532f77c317bf9df0cb3231f5c1`: four-space indentation, 150-column lines,
  and ordered imports. Format all tracked Swift files, including `Package.swift`, and run
  `swift-format lint --strict`. Public documentation remains a repository requirement even
  though this formatter does not enforce it.
- File headers use the compact license format documented below.

## Releases

- Every pull request carries exactly one label: `⚠️ semver/major`, `🆕 semver/minor`,
  `🔨 semver/patch`, or `semver/none`. The label check blocks merging without one.
- Releases are GitHub Releases, created by the Auto Release workflow: run it by hand on `main`
  and it computes the next version from the labels of the pull requests merged since the last
  release, tags it, and writes the notes from `.github/release.yml`. A major bump is refused
  there and is cut by hand.
- Consumers pin by tag, never by branch or path.

## Library CI profile

- This repository profile overrides general service CI and formatting defaults. Libraries
  never commit `Package.resolved`; CI resolves released dependencies from the manifest.
- PRs run documentation, formatting, compact license-header, shellcheck, and yamllint checks.
  Automatic API-breakage checking is disabled by project choice; SemVer labels still describe
  the public API impact. The docs workflow adds the DocC plugin only in its temporary checkout.
- PRs and main pushes run Linux tests on Swift 6.3 and 6.4, next/main snapshots, and release
  builds. PRs also run x86_64 static Linux SDK builds against the released and Swift main SDKs.
  CI has no scheduled runs. Require supported stable checks in branch protection; snapshot
  failures remain visible and advisory unless maintainers explicitly require them.
- Static SDK checks follow Swift Temporal SDK's PR-only setup and cross-compile only.
- CI is Linux-only by project choice. macOS and other Apple-platform builds/tests are
  outside this pipeline; Linux success does not establish Apple-platform compatibility.
- Shared library workflows and the SwiftNIO SemVer action follow `@main` by project choice.
  Soundness uses its release tag, and standard Actions use major-version tags. These moving
  references include upstream changes; do not describe them as immutable.
- Dependabot checks weekly, targets main, and labels workflow-update PRs `semver/none`.
- Use the three-line MIT header matched by `.license_header_template`. Keep the tools-version
  directive first in `Package.swift`, followed by that header. `.licenseignore` excludes the
  manifest (the upstream checker requires a header at line one) and the plain-text `LICENSE`.
- Keep the separate Foundation-linking consumer check on Swift 6.3 and 6.4 Noble; a successful
  static SDK build does not prove that the resolved graph avoids full Foundation.
