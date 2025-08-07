//
//  Keychain + Key.swift
//  Keychain
//
//  Created by Vaida on 2025-07-05.
//

import Foundation


extension Keychain {
    
    /// A key for defaults lookup
    ///
    /// This structure uses the primary associated value to indicate the type of the associated value.
    ///
    /// - Warning: You must not reuse an identifier, doing so will cause undefined behavior.
    public struct Key<Value>: Equatable, Sendable, Hashable {
        
        @usableFromInline
        let identifier: String
        
    }
    
}


extension Keychain.Key {
    
    /// Initialize a new defaults key.
    ///
    /// - Parameters:
    ///   - identifier: The identifier for the given key.
    @inlinable
    public init(_ identifier: String) where Value == Data {
        self.identifier = identifier
    }
    
    /// Initialize a new defaults key.
    ///
    /// - Parameters:
    ///   - identifier: The identifier for the given key.
    @inlinable
    public init(_ identifier: String) where Value == String {
        self.identifier = identifier
    }
    
    /// Initialize a new defaults key.
    ///
    /// - Parameters:
    ///   - identifier: The identifier for the given key.
    @inlinable
    public init(_ identifier: String) where Value: BinaryInteger & FixedWidthInteger {
        self.identifier = identifier
    }
    
    /// Initialize a new defaults key.
    ///
    /// - Parameters:
    ///   - identifier: The identifier for the given key.
    @inlinable
    public init(_ identifier: String) where Value: RawRepresentable, Value.RawValue == String {
        self.identifier = identifier
    }
    
    /// Initialize a new defaults key.
    ///
    /// - Parameters:
    ///   - identifier: The identifier for the given key.
    @inlinable
    public init<I>(_ identifier: String) where Value: RawRepresentable, Value.RawValue == I, I: BinaryInteger & FixedWidthInteger {
        self.identifier = identifier
    }
    
}
