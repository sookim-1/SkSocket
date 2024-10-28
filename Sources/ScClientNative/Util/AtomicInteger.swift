//
//  File.swift
//  SkSocketSwift
//
//  Created by sookim on 10/24/24.
//

import Foundation

/*
// MARK: - Class DispatchSemaphore 로 스레드 안전성 처리
public final class AtomicInteger {

    private let lock = DispatchSemaphore(value: 1)
    private var _value: Int

    public init(value initialValue: Int = 0) {
        _value = initialValue
    }

    public var value: Int {
        get {
            lock.wait()
            defer { lock.signal() }
            return _value
        }
        set {
            lock.wait()
            defer { lock.signal() }
            _value = newValue
        }
    }

    public func decrementAndGet() -> Int {
        lock.wait()
        defer { lock.signal() }
        _value -= 1

        return _value
    }

    public func incrementAndGet() -> Int {
        lock.wait()
        defer { lock.signal() }
        _value += 1

        return _value
    }

}
*/

// MARK: - actor 로 스레드 안전성 처리
actor AtomicInteger {
    private var value: Int

    public init(value: Int = 0) {
        self.value = value
    }

    public func incrementAndGet() -> Int {
        value += 1
        return value
    }

    public func decrementAndGet() -> Int {
        value -= 1
        return value
    }

    public func getValue() -> Int {
        return value
    }

    public func setValue(_ newValue: Int) {
        value = newValue
    }
}

