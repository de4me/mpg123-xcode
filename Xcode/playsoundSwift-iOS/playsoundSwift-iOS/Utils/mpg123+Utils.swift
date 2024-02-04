//
//  mpg123+Utils.swift
//  playsoundSwift-iOS
//
//  Created by DE4ME on 04.10.2022.
//

import Foundation;
import mpg123;
import out123;
import syn123;


typealias mpg123_handle = OpaquePointer;
typealias out123_handle = OpaquePointer;
typealias syn123_handle = OpaquePointer;


extension String {
    
    init?(utf8Buffer buffer: UnsafePointer<CChar>?) {
        guard let buffer = buffer, buffer.pointee != 0 else {
            return nil;
        }
        self.init(utf8String: buffer);
    }
    
}


extension mpg123_errors: Equatable {
    
    static func == (lhs: Self, rhs: Int32) -> Bool {
        return lhs.rawValue == rhs;
    }
    
    static func == (lhs: Int32, rhs: Self) -> Bool {
        return lhs == rhs.rawValue;
    }
    
    static func != (lhs: Self, rhs: Int32) -> Bool {
        return lhs.rawValue != rhs;
    }
    
    static func != (lhs: Int32, rhs: Self) -> Bool {
        return lhs != rhs.rawValue;
    }
    
}


extension out123_error: Equatable {
    
    static func == (lhs: Self, rhs: Int32) -> Bool {
        return lhs.rawValue == rhs;
    }
    
    static func == (lhs: Int32, rhs: Self) -> Bool {
        return lhs == rhs.rawValue;
    }
    
    static func != (lhs: Self, rhs: Int32) -> Bool {
        return lhs.rawValue != rhs;
    }
    
    static func != (lhs: Int32, rhs: Self) -> Bool {
        return lhs != rhs.rawValue;
    }
    
}


extension syn123_error: Equatable {
    
    static func == (lhs: Self, rhs: Int32) -> Bool {
        return lhs.rawValue == rhs;
    }
    
    static func == (lhs: Int32, rhs: Self) -> Bool {
        return lhs == rhs.rawValue;
    }
    
    static func != (lhs: Self, rhs: Int32) -> Bool {
        return lhs.rawValue != rhs;
    }
    
    static func != (lhs: Int32, rhs: Self) -> Bool {
        return lhs != rhs.rawValue;
    }
    
}


enum mpg123Error: Error {
    case mpg(Int32);
    case out(Int32);
    case syn(Int32);
    
    var string: String {
        switch self {
        case .mpg(let code):
            return String(utf8Buffer: mpg123_plain_strerror(code)) ?? "Unknown mpg error: \(code)";
        case .out(let code):
            return String(utf8Buffer: out123_plain_strerror(code)) ?? "Unknown out error: \(code)";
        case .syn(let code):
            return String(utf8Buffer: syn123_strerror(code)) ?? "Unknown syn error: \(code)";
        }
    }
    
    var errorDescription: String? {
        self.string;
    }
    
    var debugDescription: String {
        self.string;
    }
    
    init(_ error: mpg123_errors) {
        self = .mpg(error.rawValue);
    }
    
    init(_ error: out123_error) {
        self = .out(error.rawValue);
    }
    
    init(_ error: syn123_error) {
        self = .syn(Int32(error.rawValue));
    }
    
    init(mpg: mpg123_handle) {
        self = .mpg(mpg123_errcode(mpg));
    }
    
    init(out: out123_handle) {
        self = .out(out123_errcode(out));
    }
}
