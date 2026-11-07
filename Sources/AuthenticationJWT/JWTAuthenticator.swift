// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

public import Authentication
public import JWTKit

/// Proves a bearer token that is a JSON Web Token.
///
/// The credential is the token as presented, and the identity is the payload it carries, once
/// the signature verifies against the keys and the payload's own `verify(using:)` accepts its
/// claims. Authentication returns the verified payload or throws if token verification fails.
///
/// The payload's shape is the application's. The authenticator asks only that it be a
/// `JWTPayload`, and leaves which claims to enforce to the payload:
///
/// ```swift
/// struct AppToken: JWTPayload {
///     enum CodingKeys: String, CodingKey {
///         case subject = "sub"
///         case issuer = "iss"
///         case audience = "aud"
///         case expirationDate = "exp"
///         case role
///     }
///
///     let subject: String
///     let issuer: String
///     let audience: String
///     let expirationDate: Date
///     let role: String
///
///     func verify(using algorithm: some JWTAlgorithm) throws {
///         try ExpirationClaim(value: expirationDate).verifyNotExpired()
///         try AudienceClaim(value: [audience]).verifyIntendedAudience(includes: "posts")
///         guard issuer == "https://auth.example.com" else {
///             throw JWTError.claimVerificationFailure(failedClaim: IssuerClaim(value: issuer), reason: "unexpected issuer")
///         }
///     }
/// }
///
/// let keys = JWTKeyCollection()
/// await keys.add(eddsa: publicKey)
/// let authenticator = JWTAuthenticator<AppToken>(keys: keys)
/// ```
public struct JWTAuthenticator<Payload: JWTPayload>: Authenticator {
    private let keys: JWTKeyCollection

    /// An authenticator that verifies tokens against `keys`.
    ///
    /// - Parameter keys: The verification keys. Which algorithms and how many is the
    ///   application's choice. To rotate keys, add each one with its own `kid`: a collection keeps
    ///   only one key without a `kid`, and the authenticator tries every key in the collection.
    public init(keys: JWTKeyCollection) {
        self.keys = keys
    }

    /// Returns the verified payload, or throws if the token or its claims fail verification.
    ///
    /// The token is checked against the key its `kid` names, or the collection's default key when
    /// it names none, and then against every other key in the collection, so tokens signed by an
    /// old and a new key both verify during a rotation.
    public func authenticate(_ token: String) async throws -> Payload {
        try await keys.verify(token, iteratingKeys: true)
    }
}
