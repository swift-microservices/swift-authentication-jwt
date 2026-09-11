//
//  JWTIssuer.swift
//  swift-authentication-jwt
//
//  Created by Zaid Rahhawi on 9/11/26.
//

import Authentication
import JWTKit

/// Mints a bearer token that is a JSON Web Token.
///
/// The counterpart of ``JWTAuthenticator``: the one process that holds the private key issues,
/// every other holds the public key and authenticates.
///
/// ```swift
/// let keys = JWTKeyCollection()
/// await keys.add(eddsa: privateKey)
/// let issuer = JWTIssuer<AppToken>(keys: keys)
/// let token = try await issuer.issue(for: AppToken(subject: "alice", role: "user", expiration: .init(value: .now + 3600)))
/// ```
public struct JWTIssuer<Payload: JWTPayload>: CredentialIssuer {
    private let keys: JWTKeyCollection

    /// - Parameter keys: The signing keys. Which algorithms and how many is the application's
    ///   choice.
    public init(keys: JWTKeyCollection) {
        self.keys = keys
    }

    public func issue(for payload: Payload) async throws -> String {
        try await keys.sign(payload)
    }
}
