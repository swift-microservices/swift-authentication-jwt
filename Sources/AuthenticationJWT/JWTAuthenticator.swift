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
///         case expiration = "exp"
///         case role
///     }
///
///     let subject: SubjectClaim
///     let issuer: IssuerClaim
///     let audience: AudienceClaim
///     let expiration: ExpirationClaim
///     let role: String
///
///     func verify(using algorithm: some JWTAlgorithm) throws {
///         try expiration.verifyNotExpired()
///         try audience.verifyIntendedAudience(includes: "posts")
///         guard issuer.value == "https://auth.example.com" else {
///             throw JWTError.claimVerificationFailure(failedClaim: issuer, reason: "unexpected issuer")
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
    ///   application's choice.
    public init(keys: JWTKeyCollection) {
        self.keys = keys
    }

    /// Returns the verified payload, or throws if the token or its claims fail verification.
    public func authenticate(_ token: String) async throws -> Payload {
        try await keys.verify(token)
    }
}
