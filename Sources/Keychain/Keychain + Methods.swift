//
//  Keychain + Methods.swift
//  Keychain
//
//  Created by Vaida on 2025-08-07.
//

import Essentials
import Security
import Foundation


// MARK: - Data
extension Keychain {
    
    /// Loads the data associated with the given key.
    ///
    /// - Parameters:
    ///   - key: The key to entry.
    ///
    /// - throws: `KeychainError` when the entry cannot be located.
    public func load(_ key: Keychain.Key<Data>) async throws(KeychainError) -> Data {
        let query = self.query(for: key, returnData: true)

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

#if os(macOS)
        if status == errSecItemNotFound {
            return try await self.loadLegacyItemAndMigrate(key)
        }
#endif

        guard status == errSecSuccess, let data = item as? Data else { throw KeychainError(status: status) }
        return data
    }


    /// Updates the value stored in keychain service for the given key, or adds a new entry if the key does not exist.
    ///
    /// - Parameters:
    ///   - key: The key to associate with `newValue`.
    ///   - newValue: The new value to add to the keychain service.
    ///
    /// - throws: `KeychainError` when the `newValue` cannot be stored in keychain.
    public func update(_ key: Keychain.Key<Data>, to newValue: Data) async throws(KeychainError) {
        let query = self.query(for: key, valueData: newValue)

#if os(macOS)
        // must remove first, as it seems legacy and new one share the same delete query.
        try? self.removeLegacyItemIfPresent(key)
#endif
        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecSuccess { return }

        if status == errSecDuplicateItem {
            // update the entry
            let query = self.query(for: key)

            let payload: [String: Any] = [kSecValueData as String: newValue]

            let status = SecItemUpdate(query as CFDictionary, payload as CFDictionary)
            guard status == errSecSuccess else { throw KeychainError(status: status) }
#if os(macOS)
            try self.removeLegacyItemIfPresent(key)
#endif
        } else {
            throw KeychainError(status: status)
        }
    }


    /// Removes the entry associated with `key` from the keychain service
    ///
    /// - Parameters:
    ///   - key: The key to entry.
    ///
    /// - throws: `KeychainError` when the process failed.
    public func remove<T>(_ key: Keychain.Key<T>) async throws(KeychainError) {
        let query = self.query(for: key)

        let status = SecItemDelete(query as CFDictionary)
#if os(macOS)
        let legacyStatus = self.removeLegacyItem(key)
        guard status == errSecSuccess || legacyStatus == errSecSuccess else {
            throw KeychainError(status: status == errSecItemNotFound ? legacyStatus : status)
        }
#else
        guard status == errSecSuccess else { throw KeychainError(status: status) }
#endif
    }


    /// Checks whether an entry exists for the given key.
    ///
    /// - Parameters:
    ///   - key: The key to check.
    public func contains<T>(_ key: Keychain.Key<T>) -> Bool {
        let query = self.query(for: key)

        let status = SecItemCopyMatching(query as CFDictionary, nil)
#if os(macOS)
        return status == errSecSuccess || self.containsLegacyItem(key)
#else
        return status == errSecSuccess
#endif
    }

}


// MARK: - Queries

private extension Keychain {

    func query<T>(for key: Keychain.Key<T>, returnData: Bool = false, valueData: Data? = nil) -> [CFString: Any] {
        var query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: self.service,
            kSecAttrAccount: key.identifier,
            kSecUseDataProtectionKeychain: true
        ]

        if returnData {
            query[kSecMatchLimit] = kSecMatchLimitOne
            query[kSecReturnData] = true
        }

        if let valueData {
            query[kSecValueData] = valueData
        }

        return query
    }

#if os(macOS)
    func legacyQuery<T>(for key: Keychain.Key<T>, returnData: Bool = false) -> [CFString: Any] {
        var query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: self.service,
            kSecAttrAccount: key.identifier,
        ]

        if returnData {
            query[kSecMatchLimit] = kSecMatchLimitOne
            query[kSecReturnData] = true
        }

        return query
    }

    func loadLegacyItemAndMigrate(_ key: Keychain.Key<Data>) async throws(KeychainError) -> Data {
        let query = self.legacyQuery(for: key, returnData: true)

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { throw KeychainError(status: status) }

        try await self.update(key, to: data)
        return data
    }

    func containsLegacyItem<T>(_ key: Keychain.Key<T>) -> Bool {
        SecItemCopyMatching(self.legacyQuery(for: key) as CFDictionary, nil) == errSecSuccess
    }

    @discardableResult
    func removeLegacyItem<T>(_ key: Keychain.Key<T>) -> OSStatus {
        SecItemDelete(self.legacyQuery(for: key) as CFDictionary)
    }

    func removeLegacyItemIfPresent<T>(_ key: Keychain.Key<T>) throws(KeychainError) {
        let status = self.removeLegacyItem(key)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError(status: status)
        }
    }
#endif

}


// MARK: - String

extension Keychain {
    
    /// Loads the data associated with the given key.
    ///
    /// - Parameters:
    ///   - key: The key to entry.
    ///
    /// - throws: `KeychainError` when the entry cannot be located.
    @inlinable
    public func load(_ key: Keychain.Key<String>) async throws(KeychainError) -> String {
        let data = try await self.load(Key<Data>(key.identifier))
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError(status: errSecDecode)
        }
        return string
    }
    
    
    /// Updates the value stored in keychain service for the given key, or adds a new entry if the key does not exist.
    ///
    /// This methods transforms and stores the value as `utf8` data. Runtime error will occur if `newValue` is not representable as `utf8`.
    ///
    /// - Parameters:
    ///   - key: The key to associate with `newValue`.
    ///   - newValue: The new value to add to the keychain service.
    ///
    /// - throws: `KeychainError` when the `newValue` cannot be stored in keychain.
    @inlinable
    public func update(_ key: Keychain.Key<String>, to newValue: String) async throws(KeychainError) {
        guard let data = newValue.data(using: .utf8) else {
            throw KeychainError(status: errSecParam)
        }
        try await self.update(Key<Data>(key.identifier), to: data)
    }
    
}


// MARK: - Integer

extension Keychain {
    
    /// Loads the data associated with the given key.
    ///
    /// - Parameters:
    ///   - key: The key to entry.
    ///
    /// - throws: `KeychainError` when the entry cannot be located.
    @inlinable
    public func load<T>(_ key: Keychain.Key<T>) async throws(KeychainError) -> T where T: BinaryInteger & FixedWidthInteger {
        let data = try await self.load(Key<Data>(key.identifier))
        return T(data: data)
    }
    
    
    /// Updates the value stored in keychain service for the given key, or adds a new entry if the key does not exist.
    ///
    /// This methods transforms and stores the integer as the raw bit pattern native to the platform.
    ///
    /// - Parameters:
    ///   - key: The key to associate with `newValue`.
    ///   - newValue: The new value to add to the keychain service.
    ///
    /// - throws: `KeychainError` when the `newValue` cannot be stored in keychain.
    @inlinable
    public func update<T>(_ key: Keychain.Key<T>, to newValue: T) async throws(KeychainError) where T: BinaryInteger & FixedWidthInteger {
        try await self.update(Key<Data>(key.identifier), to: newValue.data)
    }
    
}


// MARK: - Raw + String

extension Keychain {
    
    /// Loads the data associated with the given key.
    ///
    /// - Parameters:
    ///   - key: The key to entry.
    ///
    /// - throws: `KeychainError` when the entry cannot be located.
    ///
    /// - Returns: `nil` when the located value is not representable as `T`.
    @inlinable
    public func load<T>(_ key: Keychain.Key<T>) async throws(KeychainError) -> T? where T: RawRepresentable, T.RawValue == String {
        let string = try await self.load(Key<String>(key.identifier))
        return T(rawValue: string)
    }
    
    
    /// Updates the value stored in keychain service for the given key, or adds a new entry if the key does not exist.
    ///
    /// - Parameters:
    ///   - key: The key to associate with `newValue`.
    ///   - newValue: The new value to add to the keychain service.
    ///
    /// This methods transforms and stores the value as `utf8` data. Runtime error will occur if `newValue`'s `rawValue` is not representable as `utf8`.
    ///
    /// - throws: `KeychainError` when the `newValue` cannot be stored in keychain.
    @inlinable
    public func update<T>(_ key: Keychain.Key<T>, to newValue: T) async throws(KeychainError) where T: RawRepresentable, T.RawValue == String {
        try await self.update(Key<String>(key.identifier), to: newValue.rawValue)
    }
    
}


// MARK: - Raw + Integer

extension Keychain {
    
    /// Loads the data associated with the given key.
    ///
    /// - Parameters:
    ///   - key: The key to entry.
    ///
    /// - throws: `KeychainError` when the entry cannot be located.
    ///
    /// - Returns: `nil` when the located value is not representable as `T`.
    @inlinable
    public func load<T, I>(_ key: Keychain.Key<T>) async throws(KeychainError) -> T? where T: RawRepresentable, T.RawValue == I, I: BinaryInteger & FixedWidthInteger {
        let int = try await self.load(Key<I>(key.identifier))
        return T(rawValue: int)
    }
    
    
    /// Updates the value stored in keychain service for the given key, or adds a new entry if the key does not exist.
    ///
    /// - Parameters:
    ///   - key: The key to associate with `newValue`.
    ///   - newValue: The new value to add to the keychain service.
    ///
    /// This methods transforms and stores the integer as the raw bit pattern native to the platform.
    ///
    /// - throws: `KeychainError` when the `newValue` cannot be stored in keychain.
    @inlinable
    public func update<T, I>(_ key: Keychain.Key<T>, to newValue: T) async throws(KeychainError) where T: RawRepresentable, T.RawValue == I, I: BinaryInteger & FixedWidthInteger {
        try await self.update(Key<I>(key.identifier), to: newValue.rawValue)
    }
    
}
