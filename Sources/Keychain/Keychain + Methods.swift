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
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: self.service,
            kSecAttrAccount as String: key.identifier,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
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
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: self.service,
            kSecAttrAccount as String: key.identifier,
            kSecValueData as String: newValue
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status != errSecSuccess else { return }
        
        if status == -25299 {
            // update the entry
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: self.service,
                kSecAttrAccount as String: key.identifier
            ]
            
            let payload: [String: Any] = [kSecValueData as String: newValue]
            
            let status = SecItemUpdate(query as CFDictionary, payload as CFDictionary)
            guard status == errSecSuccess else { throw KeychainError(status: status) }
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
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: self.service,
            kSecAttrAccount as String: key.identifier
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess else { throw KeychainError(status: status) }
    }
    
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
        return String(data: data, encoding: .utf8)!
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
        try await self.update(Key<Data>(key.identifier), to: newValue.data(using: .utf8)!)
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
