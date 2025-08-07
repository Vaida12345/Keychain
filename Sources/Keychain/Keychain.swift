//
//  Keychain.swift
//  Keychain
//
//  Created by Vaida on 2025-07-05.
//

import OSLog
import Essentials
import Foundation
import Security


/// A type-safe wrapper to Keychain Service.
///
/// The `Keychain` struct comes with a set of methods for your to interact with the keychain service.
/// ```swift
/// // updates and stores "12345"
/// try await Keychain.standard.update(.password, to: "12345")
///
/// // retrieves the value associated with `password`
/// try await Keychain.standard.load(.password) // "12345"
///
/// // removes the value associated with `password`
/// try await Keychain.standard.remove(.password)
/// ```
///
/// You can use the `Keychain.Key` struct to declare new keys. You use the primary associated type to declare the value type.
///
/// ```swift
/// extension Keychain.Key {
///     static var password: Keychain.Key<String> {
///         .init("password")
///     }
/// }
/// ```
///
/// - Warning: You must not reuse an identifier, doing so will cause undefined behavior.
public struct Keychain {
    
    @usableFromInline
    let service: String
    
    /// A global instance of `Keychain` configured to the current application.
    @inlinable
    public static var standard: Keychain {
        Keychain(service: Bundle.main.bundleIdentifier!)
    }
    
    /// A keychain with the given service name.
    public static func service(_ service: String) -> Keychain {
        Keychain(service: service)
    }
    
    @inlinable
    init(service: String) {
        self.service = service
    }
}
