//
//  JWTAuthenticator.swift
//  swift-authentication-jwt
//
//  Created by Zaid Rahhawi on 9/11/26.
//

import Authentication
import JWTKit

/// Proves a bearer token that is a JSON Web Token.
///
/// The credential is the token as presented, and the identity is the payload it carries, once
/// the signature verifies against the keys and the payload's own `verify(using:)` accepts its
/// claims. A token that fails either is refused by throwing; this authenticator never declines,
/// because a token that does not verify is not a valid credential this service happens not to
/// admit, it is an invalid one.
///
/// The payload's shape is the application's. The authenticator asks only that it be a
/// `JWTPayload`, and leaves which claims to enforce to the payload:
///
/// ```swift
/// struct AppToken: JWTPayload {
///     let subject: SubjectClaim
///     let role: String
///     let expiration: ExpirationClaim
///
///     func verify(using algorithm: some JWTAlgorithm) throws {
///         try expiration.verifyNotExpired()
///     }
/// }
///
/// let keys = JWTKeyCollection()
/// await keys.add(eddsa: publicKey)
/// let authenticator = JWTAuthenticator<AppToken>(keys: keys)
/// ```
public struct JWTAuthenticator<Payload: JWTPayload>: Authenticator {
    private let keys: JWTKeyCollection

    /// - Parameter keys: The verification keys. Which algorithms and how many is the
    ///   application's choice.
    public init(keys: JWTKeyCollection) {
        self.keys = keys
    }

    public func authenticate(_ token: String) async throws -> Payload? {
        try await keys.verify(token)
    }
}
