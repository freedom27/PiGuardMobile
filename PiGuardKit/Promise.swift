//
//  Promise.swift
//  PiGuardMobile
//
//  Created by Stefano Vettor on 06/04/16.
//  Copyright © 2016 Stefano Vettor. All rights reserved.
//

import Foundation

public enum Result<T> {
    case Success(T)
    case Error(ErrorType)
    
    public func map<U>(f: T->U) -> Result<U> {
        switch self {
        case .Error(let error): return .Error(error)
        case .Success(let t): return .Success(f(t))
        }
    }
    
    public func map<U>(f: T throws ->U) -> Result<U> {
        switch self {
        case .Error(let error): return .Error(error)
        case .Success(let t):
            do {
                return try .Success(f(t))
            } catch let error {
                return .Error(error)
            }
        }
    }
    
    public func flatMap<U>(f: T->Result<U>) -> Result<U> {
        switch self {
        case .Error(let error): return .Error(error)
        case .Success(let t): return f(t)
        }
    }
    
    public func value() throws -> T {
        switch self {
        case .Error(let error): throw error
        case .Success(let t): return t
        }
    }
}


public class Promise<T> {
    private let _queue: dispatch_queue_t
    private var _result: Result<T>?
    
    public init(c: (T->Void, ErrorType->Void)->Void) {
        _queue = dispatch_queue_create(nil, DISPATCH_QUEUE_SERIAL)
        dispatch_async(_queue) {
            dispatch_suspend(self._queue)
            c(self.onSuccess, self.onFailure)
        }
    }
    
    public init(c: (T->Void, ErrorType->Void) throws ->Void) {
        _queue = dispatch_queue_create(nil, DISPATCH_QUEUE_SERIAL)
        dispatch_async(_queue) {
            dispatch_suspend(self._queue)
            do {
                try c(self.onSuccess, self.onFailure)
            } catch let error {
                self.onFailure(error)
            }
        }
    }
    
    private init(queue: dispatch_queue_t, c: (T->Void, ErrorType->Void)->Void) {
        _queue = queue
        dispatch_async(_queue) {
            dispatch_suspend(self._queue)
            c(self.onSuccess, self.onFailure)
        }
    }
    
    private init(queue: dispatch_queue_t, c: (Result<T>->Void)->Void) {
        _queue = queue
        dispatch_async(_queue) {
            dispatch_suspend(self._queue)
            c(self.resolve)
        }
    }
    
    private func onSuccess(t: T) {
        resolve(.Success(t))
    }
    
    private func onFailure(e: ErrorType) {
        resolve(.Error(e))
    }
    
    private func resolve(response: Result<T>) {
        _result = response
        dispatch_resume(_queue)
    }
    
    public func then<U>(f: T->U) -> Promise<U> {
        return Promise<U>(queue: _queue) { resolve in
            resolve(self._result!.map(f))
        }
    }
    
    public func then<U>(f: T throws ->U) -> Promise<U> {
        return Promise<U>(queue: _queue) { resolve in
            resolve(self._result!.map(f))
        }
    }
    
    public func then<U>(f: (T, U->Void, ErrorType->Void)->Void) -> Promise<U> {
        return Promise<U>(queue: _queue) { onSuccess, onFail in
            switch self._result! {
            case .Success(let result):
                f(result, onSuccess, onFail)
            case .Error(let error):
                onFail(error)
            }
        }
    }
    
    public func then(f: T->Void) -> Promise<T> {
        dispatch_async(_queue) {
            if let result = self._result, case .Success(let value) = result {
                f(value)
            }
        }
        return self
    }
    
    public func error(f: ErrorType->Void) -> Promise<T> {
        dispatch_async(_queue) {
            if let result = self._result, case .Error(let error) = result {
                f(error)
            }
        }
        return self
    }
}

extension Promise {
    public func wait(forSeconds seconds: Double) -> Promise<T> {
        return self.then { _ in NSThread.sleepForTimeInterval(seconds) }
    }
}