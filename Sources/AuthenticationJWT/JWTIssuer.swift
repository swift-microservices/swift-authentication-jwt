// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

public import Authentication
public import JWTKit

/// Mints a bearer token that is a JSON Web Token.
///
/// The counterpart of ``JWTAuthenticator``: the one process that holds the private key issues,
/// every other holds the public key and authenticates. Naming the key's `kid` writes it into each
/// token's header, so an authenticator holding several keys during a rotation finds the right
/// one without trying the others.
///
/// ```swift
/// let keys = JWTKeyCollection()
/// await keys.add(eddsa: privateKey, kid: "2026-11")
/// let issuer = JWTIssuer<AppToken>(keys: keys, kid: "2026-11")
/// let token = try await issuer.issue(
///     for: AppToken(
///         subject: "alice",
///         issuer: "https://auth.example.com",
///         audience: "posts",
///         expirationDate: .now + 3600,
///         role: "user"
///     )
/// )
/// ```
public struct JWTIssuer<Payload: JWTPayload>: CredentialIssuer {
    private let keys: JWTKeyCollection
    private let kid: JWKIdentifier?

    /// An issuer that signs tokens with `keys`.
    ///
    /// - Parameters:
    ///   - keys: The signing keys. Which algorithms and how many is the application's choice.
    ///   - kid: The key to sign with, named in each token's `kid` header so authenticators find
    ///     its public key directly. With `nil`, the collection's default key signs and tokens
    ///     name no `kid`.
    public init(keys: JWTKeyCollection, kid: JWKIdentifier? = nil) {
        self.keys = keys
        self.kid = kid
    }

    /// Signs `payload` and returns the compact token.
    public func issue(for payload: Payload) async throws -> String {
        try await keys.sign(payload, kid: kid)
    }
}
