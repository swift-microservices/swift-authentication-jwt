// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

import Authentication
import AuthenticationJWT
import JWTKit
import Testing

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

struct TestToken: JWTPayload, Equatable {
    enum CodingKeys: String, CodingKey {
        case subject = "sub"
        case issuer = "iss"
        case audience = "aud"
        case expiration = "exp"
        case role
    }

    let subject: SubjectClaim
    let issuer: IssuerClaim
    let audience: AudienceClaim
    let expiration: ExpirationClaim
    let role: String

    func verify(using algorithm: some JWTAlgorithm) throws {
        try expiration.verifyNotExpired()
        try audience.verifyIntendedAudience(includes: "posts")
        guard issuer.value == "https://auth.example.com" else {
            throw JWTError.claimVerificationFailure(failedClaim: issuer, reason: "unexpected issuer")
        }
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
    func token(
        expiringIn seconds: TimeInterval,
        issuer: IssuerClaim = "https://auth.example.com",
        audience: AudienceClaim = "posts"
    ) -> TestToken {
        let expiration = Date(timeIntervalSince1970: (Date().timeIntervalSince1970 + seconds).rounded(.down))
        return TestToken(
            subject: "alice",
            issuer: issuer,
            audience: audience,
            expiration: ExpirationClaim(value: expiration),
            role: "user"
        )
    }

    @Test("A token the issuer minted is proved by the authenticator holding the public key")
    func issuedTokenIsAuthenticated() async throws {
        let issuer = await issuer(privateKey)
        let authenticator: any Authenticator<String, TestToken> = await authenticator(privateKey.publicKey)
        let payload = token(expiringIn: 3600)

        let credential = try await issuer.issue(for: payload)
        let identity: TestToken = try await authenticator.authenticate(credential)

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

    @Test("A token for another audience is refused")
    func foreignAudienceIsRefused() async throws {
        let issuer = await issuer(privateKey)
        let authenticator = await authenticator(privateKey.publicKey)

        let credential = try await issuer.issue(for: token(expiringIn: 3600, audience: "billing"))

        await #expect(throws: JWTError.self) {
            try await authenticator.authenticate(credential)
        }
    }

    @Test("A token from another issuer is refused")
    func foreignIssuerIsRefused() async throws {
        let issuer = await issuer(privateKey)
        let authenticator = await authenticator(privateKey.publicKey)

        let credential = try await issuer.issue(for: token(expiringIn: 3600, issuer: "https://other.example.com"))

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

    @Test("A proved payload and its token form a principal")
    func provedTokenFormsPrincipal() async throws {
        let issuer = await issuer(privateKey)
        let authenticator = await authenticator(privateKey.publicKey)
        let payload = token(expiringIn: 3600)

        let credential = try await issuer.issue(for: payload)
        let identity: TestToken = try await authenticator.authenticate(credential)
        let principal = Principal(identity: identity, credential: credential)

        #expect(principal.identity == payload)
        #expect(principal.credential == credential)
    }
}
