//
//  Keychain + Error.swift
//  Keychain
//
//  Created by Vaida on 2025-08-07.
//

import Essentials
import Security


/// Error thrown by the keychain services.
///
/// This structures serves as a wrapper to `OSStatus`, use ``status`` to obtain the underlying error code.
public struct KeychainError: GenericError {
    
    /// The underlying status code.
    ///
    /// Use `SecCopyErrorMessageString` to retrieve a human-readable message of the status code.
    public let status: OSStatus
    
    @inlinable
    public var title: String? {
        "Keychain error"
    }
    
    @inlinable
    public var message: String {
        SecCopyErrorMessageString(status, nil) as String? ?? "OSStatus code \(status)"
    }
    
    @inlinable
    public init(status: OSStatus) {
        self.status = status
    }
}
