//
//  JWTTests.swift
//  swift-authentication-jwt
//
//  Created by Zaid Rahhawi on 9/11/26.
//

import Authentication
import AuthenticationJWT
import Foundation
import JWTKit
import Testing

struct TestToken: JWTPayload, Equatable {
    let subject: SubjectClaim
    let role: String
    let expiration: ExpirationClaim

    func verify(using algorithm: some JWTAlgorithm) throws {
        try expiration.verifyNotExpired()
    }
}

@Suite
struct JWTTests {
    let privateKey = try! EdDSA.PrivateKey(curve: .ed25519)

    func issuer(_ privateKey: EdDSA.PrivateKey) async -> JWTIssuer<TestToken> {
        let keys = JWTKeyCollection()
        await keys.add(eddsa: privateKey)
        return JWTIssuer(keys: keys)
    }

    func authenticator(_ publicKey: EdDSA.PublicKey) async -> JWTAuthenticator<TestToken> {
        let keys = JWTKeyCollection()
        await keys.add(eddsa: publicKey)
        return JWTAuthenticator(keys: keys)
    }

    /// A JWT carries its expiration in whole seconds, so the date is built without a fraction to
    /// survive the round trip unchanged.
    func token(expiringIn seconds: TimeInterval) -> TestToken {
        let expiration = Date(timeIntervalSince1970: (Date().timeIntervalSince1970 + seconds).rounded(.down))
        return TestToken(subject: "alice", role: "user", expiration: ExpirationClaim(value: expiration))
    }

    @Test("A token the issuer minted is proved by the authenticator holding the public key")
    func issuedTokenIsAuthenticated() async throws {
        let issuer = await issuer(privateKey)
        let authenticator = await authenticator(privateKey.publicKey)
        let payload = token(expiringIn: 3600)

        let credential = try await issuer.issue(for: payload)
        let identity = try await authenticator.authenticate(credential)

        #expect(identity == payload)
    }

    @Test("An expired token is refused")
    func expiredTokenIsRefused() async throws {
        let issuer = await issuer(privateKey)
        let authenticator = await authenticator(privateKey.publicKey)

        let credential = try await issuer.issue(for: token(expiringIn: -60))

        await #expect(throws: JWTError.self) {
            try await authenticator.authenticate(credential)
        }
    }

    @Test("A token signed with another key is refused")
    func foreignTokenIsRefused() async throws {
        let issuer = await issuer(try EdDSA.PrivateKey(curve: .ed25519))
        let authenticator = await authenticator(privateKey.publicKey)

        let credential = try await issuer.issue(for: token(expiringIn: 3600))

        await #expect(throws: JWTError.self) {
            try await authenticator.authenticate(credential)
        }
    }

    @Test("A tampered token is refused")
    func tamperedTokenIsRefused() async throws {
        let issuer = await issuer(privateKey)
        let authenticator = await authenticator(privateKey.publicKey)

        let credential = try await issuer.issue(for: token(expiringIn: 3600))
        let tampered = credential.dropLast(4) + "AAAA"

        await #expect(throws: JWTError.self) {
            try await authenticator.authenticate(String(tampered))
        }
    }

    @Test("A proved token binds as a principal of the token")
    func provedTokenBindsAsPrincipal() async throws {
        let issuer = await issuer(privateKey)
        let authenticator = await authenticator(privateKey.publicKey)
        let payload = token(expiringIn: 3600)

        let credential = try await issuer.issue(for: payload)
        let identity = try #require(try await authenticator.authenticate(credential))
        let principal = Principal(identity: identity, credential: credential)

        #expect(principal.identity == payload)
        #expect(principal.credential == credential)
    }
}
