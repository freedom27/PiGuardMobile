//
//  Observable.swift
//  PiGuardMobile
//
//  Created by Stefano Vettor on 07/04/16.
//  Copyright © 2016 Stefano Vettor. All rights reserved.
//

import Foundation

private class Observation<T> {
    typealias ObserverClosure = (T)->Void
    let observer: ObserverClosure
    var unobserveHandler: ((Observation)->Void)?
    
    init(observer: @escaping ObserverClosure) {
        self.observer = observer
    }
}

extension Observation: Disposable {
    func dispose() {
        unobserveHandler?(self)
    }
}

public protocol Observable: class {
    associatedtype ObservedType
    
    var value: ObservedType { get set }
    func observe(_ observer: @escaping (ObservedType)->Void) -> Disposable
}

public protocol Disposable {
    func dispose()
    func addToDisposablesBag(_ bag: DisposablesBag)
}

public extension Disposable {
    public func addToDisposablesBag(_ bag: DisposablesBag) {
        bag.add(self)
    }
}


open class DisposablesBag {
    fileprivate var disposables = [Disposable]()
    
    public init() {}
    
    deinit {
        disposeAll()
    }
    
    open func add(_ disposable: Disposable) {
        disposables.append(disposable)
    }
    
    open func disposeAll() {
        disposables.forEach{$0.dispose()}
    }
}

open class Dynamic<T>: Observable {
    
    //consider to implement a lazy queue for objects deallocation
    
    open var value: T {
        didSet {
            observations.forEach{$0.observer(self.value)}
        }
    }
    
    fileprivate var observations = [Observation<T>]()
    
    public init(value: T) {
        self.value = value
    }
    
    open func observe(_ observer: @escaping (T)->Void) -> Disposable {
        let observation = Observation<T>(observer: observer)
        observation.unobserveHandler = { [weak self] (observation: Observation<T>) in
            // dispatched to the main queue to avoid issues caused by concurrency
            // since the main queue is a serial one
            DispatchQueue.main.async {
                if let newObservations = self?.observations.filter({!($0 === observation)}) {
                    self?.observations = newObservations
                }
            }
        }
        observations.append(observation)
        return observation
    }
}
