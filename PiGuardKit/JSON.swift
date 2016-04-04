//
//  JSON.swift
//  MyTVSerials
//
//  Created by Stefano Vettor on 28/11/15.
//  Copyright © 2015 Stefano Vettor. All rights reserved.
//

import Foundation

public struct JSON {
    private var _jsonObject: AnyObject?
    
    private init(object: AnyObject?) {
        _jsonObject = object;
    }
    
    public init(data: NSData) {
        _jsonObject = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
    }
}


// MARK:- Internal utility methods
extension JSON {
    private func attributeForKey<T>(key: String) -> T? {
        return _jsonObject?[key] as? T
    }
    
    private func attributeForKeyPath<T>(keys: [String]) -> T? {
        return keys.reduce( _jsonObject, combine: { element, key in element?[key] }) as? T
    }
    
    private func elementAtIndex<T>(index: Int) -> T? {
        if let array = _jsonObject as? [T] {
            return array[array.startIndex.advancedBy(index)]
        }
        return .None
    }
}

// MARK:- key subscripts returning basic types
extension JSON {
    public subscript(keys: String...) -> JSON {
        return JSON(object: attributeForKeyPath(keys))
    }
    
    public subscript(keys: String...) -> String? {
        return attributeForKeyPath(keys)
    }
    
    public subscript(keys: String...) -> Bool? {
        return attributeForKeyPath(keys)
    }
    
    public subscript(keys: String...) -> Int? {
        return attributeForKeyPath(keys)
    }
    
    public subscript(keys: String...) -> Double? {
        return attributeForKeyPath(keys)
    }
    
    public subscript(keys: String...) -> Float? {
        return attributeForKeyPath(keys)
    }
    
    public subscript(keys: [String]) -> JSON {
        return JSON(object: attributeForKeyPath(keys))
    }
    
    public subscript(keys: [String]) -> String? {
        return attributeForKeyPath(keys)
    }
    
    public subscript(keys: [String]) -> Bool? {
        return attributeForKeyPath(keys)
    }
    
    public subscript(keys: [String]) -> Int? {
        return attributeForKeyPath(keys)
    }
    
    public subscript(keys: [String]) -> Double? {
        return attributeForKeyPath(keys)
    }
    
    public subscript(keys: [String]) -> Float? {
        return attributeForKeyPath(keys)
    }
}

// MARK:- key subscripts returning arrays
extension JSON {
    public subscript(keys: String...) -> [JSON]? {
        if let objectArray: [AnyObject] = attributeForKeyPath(keys) {
            return objectArray.map{JSON(object: $0)}
        }
        return .None
    }
    
    public subscript(keys: String...) -> [String]? {
        return attributeForKeyPath(keys)
    }
    
    public subscript(keys: String...) -> [Bool]? {
        return attributeForKeyPath(keys)
    }
    
    public subscript(keys: String...) -> [Int]? {
        return attributeForKeyPath(keys)
    }
    
    public subscript(keys: String...) -> [Double]? {
        return attributeForKeyPath(keys)
    }
    
    public subscript(keys: String...) -> [Float]? {
        return attributeForKeyPath(keys)
    }
    
    public subscript(keys: [String]) -> [JSON]? {
        if let objectArray: [AnyObject] = attributeForKeyPath(keys) {
            return objectArray.map{JSON(object: $0)}
        }
        return .None
    }
    
    public subscript(keys: [String]) -> [String]? {
        return attributeForKeyPath(keys)
    }
    
    public subscript(keys: [String]) -> [Bool]? {
        return attributeForKeyPath(keys)
    }
    
    public subscript(keys: [String]) -> [Int]? {
        return attributeForKeyPath(keys)
    }
    
    public subscript(keys: [String]) -> [Double]? {
        return attributeForKeyPath(keys)
    }
    
    public subscript(keys: [String]) -> [Float]? {
        return attributeForKeyPath(keys)
    }
}

// MARK:- index subcripts returning basic types
extension JSON {
    public subscript(index: Int) -> JSON {
        return JSON(object: elementAtIndex(index))
    }
    
    public subscript(index: Int) -> String? {
        return elementAtIndex(index)
    }
    
    public subscript(index: Int) -> Bool? {
        return elementAtIndex(index)
    }
    
    public subscript(index: Int) -> Int? {
        return elementAtIndex(index)
    }
    
    public subscript(index: Int) -> Double? {
        return elementAtIndex(index)
    }
    
    public subscript(index: Int) -> Float? {
        return elementAtIndex(index)
    }
}

// MARK:- index subscripts returning arrays
extension JSON {
    public subscript(index: Int) -> [JSON]? {
        if let objectArray: [AnyObject] = elementAtIndex(index) {
            return objectArray.map{JSON(object: $0)}
        }
        return .None
    }
    
    public subscript(index: Int) -> [String]? {
        return elementAtIndex(index)
    }
    
    public subscript(index: Int) -> [Bool]? {
        return elementAtIndex(index)
    }
    
    public subscript(index: Int) -> [Int]? {
        return elementAtIndex(index)
    }
    
    public subscript(index: Int) -> [Double]? {
        return elementAtIndex(index)
    }
    
    public subscript(index: Int) -> [Float]? {
        return elementAtIndex(index)
    }
}


// MARK:- SequenceType
extension JSON: SequenceType {
    public var isEmpty: Bool {
        if let array = self._jsonObject as? [AnyObject] {
            return array.isEmpty
        } else {
            return _jsonObject != nil ? true : false
        }
    }
    
    public var count: Int {
        if let array = self._jsonObject as? [AnyObject] {
            return array.count
        } else {
            return _jsonObject != nil ? 1 : 0
        }
    }
    
    public func generate() -> AnyGenerator<JSON> {
        var index = 0
        return anyGenerator {
            if let array = self._jsonObject as? [AnyObject] where index < array.count {
                return JSON(object: array[array.startIndex.advancedBy(index++)])
            } else {
                return .None
            }
        }
    }
}

extension Dictionary {
    init<S: SequenceType where S.Generator.Element == Element>
        (_ seq: S) {
            self.init()
            for (k,v) in seq {
                self[k] = v
            }
    }
}

// MARK:- Explicit type casting
extension JSON {
    public var string: String? {
        return _jsonObject as? String
    }
    
    public var integer: Int? {
        return _jsonObject as? Int
    }
    
    public var double: Double? {
        return _jsonObject as? Double
    }
    
    public var float: Float? {
        return _jsonObject as? Float
    }
    
    public var bool: Bool? {
        return _jsonObject as? Bool
    }
    
    public var jsonArray: [JSON]? {
        if let array = _jsonObject as? [AnyObject] {
            return array.map{JSON(object: $0)}
        } else {
            return .None
        }
    }
    
    public var dictionary: [String:JSON]? {
        if let dic = _jsonObject as? [String:AnyObject] {
            return Dictionary(dic.map{($0, JSON(object: $1))})
        } else {
            return .None
        }
    }
    
    public var integerArray: [Int]? {
        return _jsonObject as? [Int]
    }
    
    public var doubleArray: [Double]? {
        return _jsonObject as? [Double]
    }
    
    public var floatArray: [Float]? {
        return _jsonObject as? [Float]
    }
    
    public var boolArray: [Bool]? {
        return _jsonObject as? [Bool]
    }
    
    public var stringArray: [String]? {
        return _jsonObject as? [String]
    }
}


// MARK:- Operator ~
prefix operator ~ {}
public prefix func ~ (json: JSON) -> String? {
    return json.string
}
public prefix func ~ (json: JSON) -> Int? {
    return json.integer
}
public prefix func ~ (json: JSON) -> Double? {
    return json.double
}
public prefix func ~ (json: JSON) -> Float? {
    return json.float
}
public prefix func ~ (json: JSON) -> Bool? {
    return json.bool
}
public prefix func ~ (json: JSON) -> [JSON]? {
    if let array = json._jsonObject as? [AnyObject] {
        return array.map{JSON(object: $0)}
    } else {
        return .None
    }
}
public prefix func ~ (json: JSON) -> [String]? {
    return json.stringArray
}
public prefix func ~ (json: JSON) -> [Int]? {
    return json.integerArray
}
public prefix func ~ (json: JSON) -> [Double]? {
    return json.doubleArray
}
public prefix func ~ (json: JSON) -> [Bool]? {
    return json.boolArray
}


// MARK:- Equatable
extension JSON: Equatable {}
public func ==(lhs: JSON, rhs: JSON) -> Bool {
    switch (lhs._jsonObject, rhs._jsonObject) {
    case let (aDictionaryL  as NSDictionary, aDictionaryR as NSDictionary):
        return aDictionaryL == aDictionaryR
    case let (anArrayL as NSArray, anArrayR as NSArray):
        return anArrayL == anArrayR
    case let (aStringL as String, aStringR as String):
        return aStringL == aStringR
    case let (aNumberL as NSNumber, aNumberR as NSNumber):
        return aNumberL == aNumberR
    case (.None(_), .None(_)):
        return true
    default:
        return false
    }
}

// MARK:- RawRepresentable
extension JSON: RawRepresentable {
    public var rawValue: AnyObject? {
        return _jsonObject
    }
    
    public init(rawValue: AnyObject?) {
        _jsonObject = rawValue
    }
}