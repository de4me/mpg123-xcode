//
//  mpg123+Utils.swift
//  playsoundSwift
//
//  Created by DE4ME on 04.10.2022.
//

import Foundation;
import mpg123;
import out123;


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


struct mpg123Error: Error, LocalizedError, CustomDebugStringConvertible {
        
    let code: Int32;
    
    var string: String {
        String(utf8Buffer: mpg123_plain_strerror(self.code)) ?? "Unknown error: \(self.code)";
    }
    
    var errorDescription: String? {
        self.string;
    }
    
    var debugDescription: String {
        self.string;
    }
    
    init(code: Int32) {
        self.code = code;
    }
    
    init(_ error: mpg123_errors) {
        self.code = error.rawValue;
    }
    
    init(_ mh: mpg123_handle) {
        self.code = mpg123_errcode(mh);
    }
    
}


struct out123Error: Error, LocalizedError, CustomDebugStringConvertible {
    
    let code: Int32;
    
    var string: String {
        String(utf8Buffer: out123_plain_strerror(self.code)) ?? "Unknown error: \(self.code)";
    }
    
    var errorDescription: String? {
        self.string;
    }
    
    var debugDescription: String {
        self.string;
    }
    
    init(code: Int32) {
        self.code = code;
    }
    
    init(_ error: out123_error) {
        self.code = error.rawValue;
    }
    
    init(_ ao: out123_handle) {
        self.code = out123_errcode(ao);
    }
    
}
