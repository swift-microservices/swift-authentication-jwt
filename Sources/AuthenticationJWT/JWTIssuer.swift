// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

public import Authentication
public import JWTKit

/// Mints a bearer token that is a JSON Web Token.
///
/// The counterpart of ``JWTAuthenticator``: the one process that holds the private key issues,
/// every other holds the public key and authenticates.
///
/// ```swift
/// let keys = JWTKeyCollection()
/// await keys.add(eddsa: privateKey)
/// let issuer = JWTIssuer<AppToken>(keys: keys)
/// let token = try await issuer.issue(
///     for: AppToken(
///         subject: "alice",
///         issuer: "https://auth.example.com",
///         audience: "posts",
///         expiration: .init(value: .now + 3600),
///         role: "user"
///     )
/// )
/// ```
public struct JWTIssuer<Payload: JWTPayload>: CredentialIssuer {
    private let keys: JWTKeyCollection

    /// An issuer that signs tokens with `keys`.
    ///
    /// - Parameter keys: The signing keys. Which algorithms and how many is the application's
    ///   choice.
    public init(keys: JWTKeyCollection) {
        self.keys = keys
    }

    /// Signs `payload` and returns the compact token.
    public func issue(for payload: Payload) async throws -> String {
        try await keys.sign(payload)
    }
}
