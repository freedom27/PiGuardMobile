//
//  Promise.swift
//  PiGuardMobile
//
//  Created by Stefano Vettor on 06/04/16.
//  Copyright © 2016 Stefano Vettor. All rights reserved.
//

import Foundation

public enum Result<T> {
    case success(T)
    case error(Error)
    
    public func map<U>(_ f: (T)->U) -> Result<U> {
        switch self {
        case .error(let error): return .error(error)
        case .success(let t): return .success(f(t))
        }
    }
    
    public func map<U>(_ f: (T) throws ->U) -> Result<U> {
        switch self {
        case .error(let error): return .error(error)
        case .success(let t):
            do {
                return try .success(f(t))
            } catch let error {
                return .error(error)
            }
        }
    }
    
    public func flatMap<U>(_ f: (T)->Result<U>) -> Result<U> {
        switch self {
        case .error(let error): return .error(error)
        case .success(let t): return f(t)
        }
    }
    
    public func value() throws -> T {
        switch self {
        case .error(let error): throw error
        case .success(let t): return t
        }
    }
}


open class Promise<T> {
    fileprivate let _queue: DispatchQueue
    fileprivate var _result: Result<T>?
    
    public init(c: @escaping (@escaping (T)->Void, @escaping (Error)->Void)->Void) {
        _queue = DispatchQueue(label: "MyPromise")
        _queue.async {
            self._queue.suspend()
            c(self.onSuccess, self.onFailure)
        }
    }
    
    public init(c: @escaping (@escaping (T)->Void, @escaping (Error)->Void) throws ->Void) {
        _queue = DispatchQueue(label: "MyPromise")
        _queue.async {
            self._queue.suspend()
            do {
                try c(self.onSuccess, self.onFailure)
            } catch let error {
                self.onFailure(error)
            }
        }
    }
    
    fileprivate init(queue: DispatchQueue, c: @escaping (@escaping (T)->Void, @escaping (Error)->Void)->Void) {
        _queue = queue
        _queue.async {
            self._queue.suspend()
            c(self.onSuccess, self.onFailure)
        }
    }
    
    fileprivate init(queue: DispatchQueue, c: @escaping ( @escaping (Result<T>)->Void)->Void) {
        _queue = queue
        _queue.async {
            self._queue.suspend()
            c(self.resolve)
        }
    }
    
    fileprivate func onSuccess(_ t: T) {
        resolve(.success(t))
    }
    
    fileprivate func onFailure(_ e: Error) {
        resolve(.error(e))
    }
    
    fileprivate func resolve(_ response: Result<T>) {
        _result = response
        _queue.resume()
    }
    
    open func then<U>(_ f: @escaping (T)->U) -> Promise<U> {
        return Promise<U>(queue: _queue) { resolve in
            resolve(self._result!.map(f))
        }
    }
    
    open func then<U>(_ f: @escaping (T) throws ->U) -> Promise<U> {
        return Promise<U>(queue: _queue) { resolve in
            resolve(self._result!.map(f))
        }
    }
    
    open func then<U>(_ f: @escaping (T, (U)->Void, (Error)->Void)->Void) -> Promise<U> {
        return Promise<U>(queue: _queue) { onSuccess, onFail in
            switch self._result! {
            case .success(let result):
                f(result, onSuccess, onFail)
            case .error(let error):
                onFail(error)
            }
        }
    }
    
    open func then(_ f: @escaping (T)->Void) -> Promise<T> {
        _queue.async {
            if let result = self._result, case .success(let value) = result {
                f(value)
            }
        }
        return self
    }
    
    open func error(_ f: @escaping (Error)->Void) -> Promise<T> {
        _queue.async {
            if let result = self._result, case .error(let error) = result {
                f(error)
            }
        }
        return self
    }
}

extension Promise {
    public func wait(forSeconds seconds: Double) -> Promise<T> {
        return self.then { _ in Thread.sleep(forTimeInterval: seconds) }
    }
}
