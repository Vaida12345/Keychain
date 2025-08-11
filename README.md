# Keychain

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

> Warning:
> You must not reuse an identifier, doing so will cause undefined behavior.


## Getting Started

`Keychain` uses [Swift Package Manager](https://www.swift.org/documentation/package-manager/) as its build tool. If you want to import in your own project, it's as simple as adding a `dependencies` clause to your `Package.swift`:
```swift
dependencies: [
    .package(url: "https://github.com/Vaida12345/Keychain.git", from: "1.0.0")
]
```
and then adding the appropriate module to your target dependencies.

### Using Xcode Package support

You can add this framework as a dependency to your Xcode project by clicking File -> Swift Packages -> Add Package Dependency. The package is located at:
```
https://github.com/Vaida12345/Keychain.git
```

## Documentation

This package uses [DocC](https://www.swift.org/documentation/docc/) for documentation.
