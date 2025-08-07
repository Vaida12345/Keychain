import Testing
import Keychain
import Foundation


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
            let _ = try await Keychain.standard.load(.password)
        }
    }
    
    @Test func integer() async throws {
        try await Keychain.standard.update(.integer, to: 12345)
        #expect(try await Keychain.standard.load(.integer) == 12345)
        
        try await Keychain.standard.remove(.integer)
        await #expect(throws: KeychainError.self) {
            let _ = try await Keychain.standard.load(.integer)
        }
    }
    
    @Test func update() async throws {
        try await Keychain.standard.update(.integer, to: 12345)
        #expect(try await Keychain.standard.load(.integer) == 12345)
        
        try await Keychain.standard.update(.integer, to: 45678)
        #expect(try await Keychain.standard.load(.integer) == 45678)
        
        try await Keychain.standard.remove(.integer)
        await #expect(throws: KeychainError.self) {
            let _ = try await Keychain.standard.load(.integer)
        }
    }
    
    
    @Test func stringRaw() async throws {
        try await Keychain.standard.update(.stringRaw, to: .c)
        #expect(try await Keychain.standard.load(.stringRaw) == .c)
        
        try await Keychain.standard.remove(.stringRaw)
        await #expect(throws: KeychainError.self) {
            let _ = try await Keychain.standard.load(.stringRaw)
        }
    }
    
    @Test func integerRaw() async throws {
        try await Keychain.standard.update(.integerRaw, to: .c)
        #expect(try await Keychain.standard.load(.integerRaw) == .c)
        
        try await Keychain.standard.remove(.integerRaw)
        await #expect(throws: KeychainError.self) {
            let _ = try await Keychain.standard.load(.integerRaw)
        }
    }
    
}
