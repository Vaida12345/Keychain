# ``Keychain``

A type-safe wrapper to Keychain Service.

## Overview

The `Keychain` struct comes with a set of methods for your to interact with the keychain service.
```swift
// updates and stores "12345"
try await Keychain.standard.update(.password, to: "12345")

// retrieves the value associated with `password`
try await Keychain.standard.load(.password) // "12345"

// removes the value associated with `password`
try await Keychain.standard.remove(.password)
```

You can use the `Keychain.Key` struct to declare new keys. You use the primary associated type to declare the value type.

```swift
extension Keychain.Key {
    static var password: Keychain.Key<String> {
        .init("password")
    }
}
```

- Warning: You must not reuse an identifier, doing so will cause undefined behavior.

## Topics

### Keychain

- ``Keychain``


### KeychainError

- ``KeychainError``
