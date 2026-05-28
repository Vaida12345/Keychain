import Testing
@testable import Keychain
import Foundation
import Security


extension Keychain.Key {
    
    static var password: Keychain.Key<String> {
        .init("password")
    }
    
    static var integer: Keychain.Key<Int> {
        .init("integer")
    }
    
    static var stringRaw: Keychain.Key<StringRaw> {
        .init("stringRaw")
    }
    
    static var integerRaw: Keychain.Key<IntegerRaw> {
        .init("integerRaw")
    }

    static var legacyData: Keychain.Key<Data> {
        .init("legacyData")
    }

}


enum IntegerRaw: UInt8 {
    case a, b, c, d
}

enum StringRaw: String {
    case a, b, c, d
}


@Suite(.serialized) struct KeychainTests {
    
    @Test func string() async throws {
        try await Keychain.standard.update(.password, to: "12345")
        #expect(try await Keychain.standard.load(.password) == "12345")
        
        try await Keychain.standard.remove(.password)
        await #expect(throws: KeychainError.self) {
            _ = try await Keychain.standard.load(.password)
        }
    }
    
    @Test func integer() async throws {
        try await Keychain.standard.update(.integer, to: 12345)
        #expect(try await Keychain.standard.load(.integer) == 12345)
        
        try await Keychain.standard.remove(.integer)
        await #expect(throws: KeychainError.self) {
            _ = try await Keychain.standard.load(.integer)
        }
    }
    
    @Test func update() async throws {
        try await Keychain.standard.update(.integer, to: 12345)
        #expect(try await Keychain.standard.load(.integer) == 12345)
        
        try await Keychain.standard.update(.integer, to: 45678)
        #expect(try await Keychain.standard.load(.integer) == 45678)
        
        try await Keychain.standard.remove(.integer)
        await #expect(throws: KeychainError.self) {
            _ = try await Keychain.standard.load(.integer)
        }
    }
    
    
    @Test func stringRaw() async throws {
        try await Keychain.standard.update(.stringRaw, to: .c)
        #expect(try await Keychain.standard.load(.stringRaw) == .c)
        
        try await Keychain.standard.remove(.stringRaw)
        await #expect(throws: KeychainError.self) {
            _ = try await Keychain.standard.load(.stringRaw)
        }
    }
    
    @Test func integerRaw() async throws {
        try await Keychain.standard.update(.integerRaw, to: .c)
        #expect(try await Keychain.standard.load(.integerRaw) == .c)
        
        try await Keychain.standard.remove(.integerRaw)
        await #expect(throws: KeychainError.self) {
            _ = try await Keychain.standard.load(.integerRaw)
        }
    }
    
    @Test(.enabled(if: legacyKeychainTestsAreSupported)) func legacyItemIsMigratedOnLoad() async throws {
        let service = "KeychainTests.legacyItemIsMigratedOnLoad"
        let keychain = Keychain.service(service)
        let value = Data("legacy-value".utf8)

        removeItem(service: service, key: .legacyData, usesDataProtectionKeychain: false)
        removeItem(service: service, key: .legacyData, usesDataProtectionKeychain: true)
        defer {
            removeItem(service: service, key: .legacyData, usesDataProtectionKeychain: false)
            removeItem(service: service, key: .legacyData, usesDataProtectionKeychain: true)
        }

        #expect(addItem(service: service, key: .legacyData, value: value, usesDataProtectionKeychain: false) == errSecSuccess)

        #expect(try await keychain.load(.legacyData) == value)
        #expect(containsItem(service: service, key: .legacyData, usesDataProtectionKeychain: true))
        #expect(!containsItem(service: service, key: .legacyData, usesDataProtectionKeychain: false))
    }

    @Test(.enabled(if: legacyKeychainTestsAreSupported)) func removeDeletesLegacyDuplicate() async throws {
        let service = "KeychainTests.removeDeletesLegacyDuplicate"
        let keychain = Keychain.service(service)
        let legacyValue = Data("legacy-value".utf8)
        let currentValue = Data("current-value".utf8)

        removeItem(service: service, key: .legacyData, usesDataProtectionKeychain: false)
        removeItem(service: service, key: .legacyData, usesDataProtectionKeychain: true)
        defer {
            removeItem(service: service, key: .legacyData, usesDataProtectionKeychain: false)
            removeItem(service: service, key: .legacyData, usesDataProtectionKeychain: true)
        }

        #expect(addItem(service: service, key: .legacyData, value: legacyValue, usesDataProtectionKeychain: false) == errSecSuccess)
        #expect(addItem(service: service, key: .legacyData, value: currentValue, usesDataProtectionKeychain: true) == errSecSuccess)

        try await keychain.remove(.legacyData)

        #expect(!containsItem(service: service, key: .legacyData, usesDataProtectionKeychain: true))
        #expect(!containsItem(service: service, key: .legacyData, usesDataProtectionKeychain: false))
        await #expect(throws: KeychainError.self) {
            _ = try await keychain.load(.legacyData)
        }
    }

}


#if os(macOS)
let legacyKeychainTestsAreSupported = true
#else
let legacyKeychainTestsAreSupported = false
#endif


private func query<T>(
    service: String,
    key: Keychain.Key<T>,
    value: Data? = nil,
    usesDataProtectionKeychain: Bool
) -> [CFString: Any] {
    var query: [CFString: Any] = [
        kSecClass: kSecClassGenericPassword,
        kSecAttrService: service,
        kSecAttrAccount: key.identifier,
        kSecUseDataProtectionKeychain: usesDataProtectionKeychain
    ]

    if let value {
        query[kSecValueData] = value
    }

    return query
}


@discardableResult
private func addItem<T>(
    service: String,
    key: Keychain.Key<T>,
    value: Data,
    usesDataProtectionKeychain: Bool
) -> OSStatus {
    SecItemAdd(query(service: service, key: key, value: value, usesDataProtectionKeychain: usesDataProtectionKeychain) as CFDictionary, nil)
}


private func removeItem<T>(service: String, key: Keychain.Key<T>, usesDataProtectionKeychain: Bool) {
    SecItemDelete(query(service: service, key: key, usesDataProtectionKeychain: usesDataProtectionKeychain) as CFDictionary)
}


private func containsItem<T>(service: String, key: Keychain.Key<T>, usesDataProtectionKeychain: Bool) -> Bool {
    SecItemCopyMatching(query(service: service, key: key, usesDataProtectionKeychain: usesDataProtectionKeychain) as CFDictionary, nil) == errSecSuccess
}
