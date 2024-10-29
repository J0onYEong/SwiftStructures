//
//  LockedDictionary.swift
//  SwiftStructures
//
//  Created by choijunios on 10/11/24.
//

import Foundation

public class LockedDictionary<Key, Value> where Key: Hashable {
    
    typealias Source = Dictionary<Key, Value>
    
    private var source: Source = [:]
    
    private let lock: NSLock = .init()
    
    public init() { }
    
    public subscript(key: Key) -> Value? {
        get {
            defer {
                lock.unlock()
            }
            lock.lock()
            return source[key]
        }
        set(newValue) {
            defer {
                lock.unlock()
            }
            lock.lock()
            source[key] = newValue
        }
    }
    
    public func remove(key: Key) {
        defer {
            lock.unlock()
        }
        lock.lock()
        source.removeValue(forKey: key)
    }
}

