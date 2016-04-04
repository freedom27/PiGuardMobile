//
//  Observable.swift
//  PiGuardMobile
//
//  Created by Stefano Vettor on 07/04/16.
//  Copyright © 2016 Stefano Vettor. All rights reserved.
//

import Foundation

private class Observation<T> {
    typealias ObserverClosure = T->Void
    let observer: ObserverClosure
    var unobserveHandler: (Observation->Void)?
    
    init(observer: ObserverClosure) {
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
    func observe(observer: ObservedType->Void) -> Disposable
}

public protocol Disposable {
    func dispose()
    func addToDisposablesBag(bag: DisposablesBag)
}

public extension Disposable {
    public func addToDisposablesBag(bag: DisposablesBag) {
        bag.add(self)
    }
}


public class DisposablesBag {
    private var disposables = [Disposable]()
    
    public init() {}
    
    deinit {
        disposeAll()
    }
    
    public func add(disposable: Disposable) {
        disposables.append(disposable)
    }
    
    public func disposeAll() {
        disposables.forEach{$0.dispose()}
    }
}

public class Dynamic<T>: Observable {
    
    //consider to implement a lazy queue for objects deallocation
    
    public var value: T {
        didSet {
            observations.forEach{$0.observer(self.value)}
        }
    }
    
    private var observations = [Observation<T>]()
    
    public init(value: T) {
        self.value = value
    }
    
    public func observe(observer: T->Void) -> Disposable {
        let observation = Observation<T>(observer: observer)
        observation.unobserveHandler = { [weak self] (observation: Observation<T>) in
            // dispatched to the main queue to avoid issues caused by concurrency
            // since the main queue is a serial one
            dispatch_async(dispatch_get_main_queue()) {
                if let newObservations = self?.observations.filter({!($0 === observation)}) {
                    self?.observations = newObservations
                }
            }
        }
        observations.append(observation)
        return observation
    }
}