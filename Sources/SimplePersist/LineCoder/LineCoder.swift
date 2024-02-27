//
//  File.swift
//
//
//  Created by Carlyn Maw on 2/26/24.
//  https://github.com/apple/swift-corelibs-foundation/blob/806ba24a520a7803bfb3145d5706480fca41f38c/Sources/Foundation/JSONEncoder.swift#L27
//https://github.com/apple/swift-corelibs-foundation/blob/5a1db791ab824e29dc45ce08f729d3541f0517d0/Sources/Foundation/JSONSerialization%2BParser.swift#L635

import Foundation

fileprivate protocol _DictionaryIsEncodableMarker { }
extension Dictionary: _DictionaryIsEncodableMarker where Key == String, Value: Encodable { }


final class LineMaker {
    //--------------------------------------------------------- FROM JSONEncoder
    public enum DateEncodingStrategy {
        /// Defer to `Date` for choosing an encoding. This is the default strategy.
        case deferredToDate
        
        /// Encode the `Date` as a UNIX timestamp (as a JSON number).
        case secondsSince1970
        
        /// Encode the `Date` as UNIX millisecond timestamp (as a JSON number).
        case millisecondsSince1970
        
        /// Encode the `Date` as an ISO-8601-formatted string (in RFC 3339 format).
        @available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
        case iso8601
        
        /// Encode the `Date` as a string formatted by the given formatter.
        case formatted(DateFormatter)
        
        /// Encode the `Date` as a custom value encoded by the given closure.
        ///
        /// If the closure fails to encode a value into the given encoder, the encoder will encode an empty automatic container in its place.
        case custom((Date, Encoder) throws -> Void)
    }
    
    /// The strategy to use for encoding `Data` values.
    public enum DataEncodingStrategy {
        /// Defer to `Data` for choosing an encoding.
        case deferredToData
        
        /// Encoded the `Data` as a Base64-encoded string. This is the default strategy.
        case base64
        
        /// Encode the `Data` as a custom value encoded by the given closure.
        ///
        /// If the closure fails to encode a value into the given encoder, the encoder will encode an empty automatic container in its place.
        case custom((Data, Encoder) throws -> Void)
    }
    
    /// The strategy to use for non-JSON-conforming floating-point values (IEEE 754 infinity and NaN).
    public enum NonConformingFloatEncodingStrategy {
        /// Throw upon encountering non-conforming values. This is the default strategy.
        case `throw`
        
        /// Encode the values using the given representation strings.
        case convertToString(positiveInfinity: String, negativeInfinity: String, nan: String)
    }
    
    /// The strategy to use for automatically changing the value of keys before encoding.
    public enum KeyEncodingStrategy {
        /// Use the keys specified by each type. This is the default strategy.
        case useDefaultKeys
        
        /// Convert from "camelCaseKeys" to "snake_case_keys" before writing a key to JSON payload.
        ///
        /// Capital characters are determined by testing membership in `CharacterSet.uppercaseLetters` and `CharacterSet.lowercaseLetters` (Unicode General Categories Lu and Lt).
        /// The conversion to lower case uses `Locale.system`, also known as the ICU "root" locale. This means the result is consistent regardless of the current user's locale and language preferences.
        ///
        /// Converting from camel case to snake case:
        /// 1. Splits words at the boundary of lower-case to upper-case
        /// 2. Inserts `_` between words
        /// 3. Lowercases the entire string
        /// 4. Preserves starting and ending `_`.
        ///
        /// For example, `oneTwoThree` becomes `one_two_three`. `_oneTwoThree_` becomes `_one_two_three_`.
        ///
        /// - Note: Using a key encoding strategy has a nominal performance cost, as each string key has to be converted.
        case convertToSnakeCase
        
        /// Provide a custom conversion to the key in the encoded JSON from the keys specified by the encoded types.
        /// The full path to the current encoding position is provided for context (in case you need to locate this key within the payload). The returned key is used in place of the last component in the coding path before encoding.
        /// If the result of the conversion is a duplicate key, then only one value will be present in the result.
        case custom((_ codingPath: [CodingKey]) -> CodingKey)
        
        fileprivate static func _convertToSnakeCase(_ stringKey: String) -> String {
            guard !stringKey.isEmpty else { return stringKey }
            
            var words: [Range<String.Index>] = []
            // The general idea of this algorithm is to split words on transition from lower to upper case, then on transition of >1 upper case characters to lowercase
            //
            // myProperty -> my_property
            // myURLProperty -> my_url_property
            //
            // We assume, per Swift naming conventions, that the first character of the key is lowercase.
            var wordStart = stringKey.startIndex
            var searchRange = stringKey.index(after: wordStart)..<stringKey.endIndex
            
            // Find next uppercase character
            while let upperCaseRange = stringKey.rangeOfCharacter(from: CharacterSet.uppercaseLetters, options: [], range: searchRange) {
                let untilUpperCase = wordStart..<upperCaseRange.lowerBound
                words.append(untilUpperCase)
                
                // Find next lowercase character
                searchRange = upperCaseRange.lowerBound..<searchRange.upperBound
                guard let lowerCaseRange = stringKey.rangeOfCharacter(from: CharacterSet.lowercaseLetters, options: [], range: searchRange) else {
                    // There are no more lower case letters. Just end here.
                    wordStart = searchRange.lowerBound
                    break
                }
                
                // Is the next lowercase letter more than 1 after the uppercase? If so, we encountered a group of uppercase letters that we should treat as its own word
                let nextCharacterAfterCapital = stringKey.index(after: upperCaseRange.lowerBound)
                if lowerCaseRange.lowerBound == nextCharacterAfterCapital {
                    // The next character after capital is a lower case character and therefore not a word boundary.
                    // Continue searching for the next upper case for the boundary.
                    wordStart = upperCaseRange.lowerBound
                } else {
                    // There was a range of >1 capital letters. Turn those into a word, stopping at the capital before the lower case character.
                    let beforeLowerIndex = stringKey.index(before: lowerCaseRange.lowerBound)
                    words.append(upperCaseRange.lowerBound..<beforeLowerIndex)
                    
                    // Next word starts at the capital before the lowercase we just found
                    wordStart = beforeLowerIndex
                }
                searchRange = lowerCaseRange.upperBound..<searchRange.upperBound
            }
            words.append(wordStart..<searchRange.upperBound)
            let result = words.map({ (range) in
                return stringKey[range].lowercased()
            }).joined(separator: "_")
            return result
        }
    }
    
    /// The output format to produce. Defaults to `[]`.
    //open var outputFormatting: OutputFormatting = []
    
    /// The strategy to use in encoding dates. Defaults to `.deferredToDate`.
    var dateEncodingStrategy: DateEncodingStrategy = .deferredToDate
    
    /// The strategy to use in encoding binary data. Defaults to `.base64`.
    var dataEncodingStrategy: DataEncodingStrategy = .base64
    
    /// The strategy to use in encoding non-conforming numbers. Defaults to `.throw`.
    var nonConformingFloatEncodingStrategy: NonConformingFloatEncodingStrategy = .throw
    
    /// The strategy to use for encoding keys. Defaults to `.useDefaultKeys`.
    var keyEncodingStrategy: KeyEncodingStrategy = .useDefaultKeys
    
    /// Contextual user-provided information for use during encoding.
    var userInfo: [CodingUserInfoKey: Any] = [:]
    
    /// Options set on the top-level encoder to pass down the encoding hierarchy.
    fileprivate struct _Options {
        let dateEncodingStrategy: DateEncodingStrategy
        let dataEncodingStrategy: DataEncodingStrategy
        let nonConformingFloatEncodingStrategy: NonConformingFloatEncodingStrategy
        let keyEncodingStrategy: KeyEncodingStrategy
        let userInfo: [CodingUserInfoKey: Any]
    }
    
    /// The options set on the top-level encoder.
    fileprivate var options: _Options {
        return _Options(dateEncodingStrategy: dateEncodingStrategy,
                        dataEncodingStrategy: dataEncodingStrategy,
                        nonConformingFloatEncodingStrategy: nonConformingFloatEncodingStrategy,
                        keyEncodingStrategy: keyEncodingStrategy,
                        userInfo: userInfo)
    }
    
    // MARK: - Constructing a JSON Encoder
    
    /// Initializes `self` with default strategies.
    public init() {}
    
    
    //--------------------------------------------------------- END JSONEncoder
    
    //MARK: Encode
    public func encode<T: Encodable>(_ value: T) throws -> Data {
        let value:EncodedValue = try encodeValue(value)
        let writer = EncodedValue.Writer()
    }
    
    //This is all about making sure the individual items can be stringified.
    func encodeValue<T: Encodable>(_ value: T) throws -> EncodedValue {
        let encoder = LineEncoderImplementation(options: options, codingPath: [])
        guard let topLevel = try encoder.wrapEncodable(value, additionalKey: nil) else {
            //TODO: This in not my error.
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "Top-level \(T.self) did not encode any values."))
        }
        
        return topLevel
    }
    
}




fileprivate final class LineEncoderImplementation {
    
    init(options: LineMaker._Options, codingPath: [CodingKey]) {
        self.options = options
        self.codingPath = codingPath
    }
    
    var options:LineMaker._Options
    
    //needed for Encoder Implementation.
    var codingPath: [CodingKey]
    var userInfo: [CodingUserInfoKey : Any]  { [:] }
    
    var thisInstance:Self {
        self
    }
    
    var singleValue: EncodedValue?
    //var array: JSONFuture.RefArray?
    //var object: JSONFuture.RefObject?
    
    var value: EncodedValue? {
//        if let object = self.object {
//            return .object(object.values)
//        }
//        if let array = self.array {
//            return .array(array.values)
//        }
        return self.singleValue
    }
    
}
    
extension LineEncoderImplementation: Encoder {
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        fatalError()
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        fatalError()
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        fatalError()
    }
    
}
//MARK: Writer
fileprivate extension LineEncoderImplementation {
    struct Writer {
        //let options: SomeFutureOptionSet
        
        func writeValue(_ value: EncodedValue) -> [UInt8] {
            var bytes = [UInt8]()
            //options handled
            self.writeValue(value, into: &bytes)
        }
        
        private func writeValue(_ value: EncodedValue, into bytes: inout [UInt8]) {
            switch value {
            case .null:
                bytes.append(contentsOf: [UInt8]._null)
            case .bool(true):
                bytes.append(contentsOf: [UInt8]._true)
            case .bool(false):
                bytes.append(contentsOf: [UInt8]._false)
            case .string(let string):
                bytes.append(contentsOf: string.utf8)
                //JSON needs some specific stuff see Line 1109 in JSONEncoder.swift
                //self.encodeString(string, to: &bytes)
            case .number(let string):
                bytes.append(contentsOf: string.utf8)
            case .array(let array):
                fatalError()
                //                        var iterator = array.makeIterator()
                //                        bytes.append(._openbracket)
                //                        // we don't like branching, this is why we have this extra
                //                        if let first = iterator.next() {
                //                            self.writeValue(first, into: &bytes)
                //                        }
                //                        while let item = iterator.next() {
                //                            bytes.append(._comma)
                //                            self.writeValue(item, into:&bytes)
                //                        }
                //                        bytes.append(._closebracket)
            case .object(let dict):
                fatalError()
                //                        if #available(macOS 10.13, *), options.contains(.sortedKeys) {
                //                            let sorted = dict.sorted { $0.key.compare($1.key, options: [.caseInsensitive, .diacriticInsensitive, .forcedOrdering, .numeric, .widthInsensitive]) == .orderedAscending }
                //                            self.writeObject(sorted, into: &bytes)
                //                        } else {
                //                            self.writeObject(dict, into: &bytes)
                //                        }
            }
        }
        
       
    }
}


//MARK: Item -> String
fileprivate extension LineEncoderImplementation {
    
    //changed "for" to additional key because for was ambiguous.
    func wrapEncodable<E: Encodable>(_ encodable: E, additionalKey: CodingKey?) throws -> EncodedValue? {
        switch encodable {
        case let date as Date:
            return try self.wrapDate(date, additionalKey: additionalKey)
        case let data as Data:
            return try self.wrapData(data, additionalKey: additionalKey)
        case let url as URL:
            return .string(url.absoluteString)
        case let decimal as Decimal:
            return .number(decimal.description)
//        case let object as _DictionaryIsEncodableMarker:
//            return try self.wrapObject(object as! [String: Encodable], for: additionalKey)
        default:
            let encoder = self.getEncoder(for: additionalKey)
            try encodable.encode(to: encoder)
            return encoder.value
        }
    }
    
    func wrapDate(_ date: Date, additionalKey: CodingKey?) throws -> EncodedValue {
        switch self.options.dateEncodingStrategy {
        case .deferredToDate:
            let encoder = self.getEncoder(for: additionalKey)
            try date.encode(to: encoder)
            return encoder.value ?? .null
            
        case .secondsSince1970:
            return .number(date.timeIntervalSince1970.description)
            
        case .millisecondsSince1970:
            return .number((date.timeIntervalSince1970 * 1000).description)
            
        case .iso8601:
            if #available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *) {
                return .string(_iso8601Formatter.string(from: date))
            } else {
                fatalError("ISO8601DateFormatter is unavailable on this platform.")
            }
            
        case .formatted(let formatter):
            return .string(formatter.string(from: date))
            
        case .custom(let closure):
            let encoder = self.getEncoder(for: additionalKey)
            try closure(date, encoder)
            // The closure didn't encode anything. Return the default keyed container.
            return encoder.value ?? .object([:])
        }
    }
    
    func wrapData(_ data: Data, additionalKey: CodingKey?) throws -> EncodedValue {
        switch self.options.dataEncodingStrategy {
        case .deferredToData:
            let encoder = self.getEncoder(for: additionalKey)
            try data.encode(to: encoder)
            return encoder.value ?? .null
            
        case .base64:
            let base64 = data.base64EncodedString()
            return .string(base64)
            
        case .custom(let closure):
            let encoder = self.getEncoder(for: additionalKey)
            try closure(data, encoder)
            // The closure didn't encode anything. Return the default keyed container.
            return encoder.value ?? .object([:])
        }
    }
    
//    func wrapObject(_ object: [String: Encodable], for additionalKey: CodingKey?) throws -> EncodedValue {
//        var baseCodingPath = self.codingPath
//        if let additionalKey = additionalKey {
//            baseCodingPath.append(additionalKey)
//        }
//        var result = [String: EncodedValue]()
//        result.reserveCapacity(object.count)
//        
//        try object.forEach { (key, value) in
//            var elemCodingPath = baseCodingPath
//            elemCodingPath.append(_PotentialNumericKey(stringValue: key, intValue: nil))
//            let encoder = Self(options: self.options, codingPath: elemCodingPath)
//            
//            result[key] = try encoder.wrapUntyped(value)
//        }
//        
//        return .object(result)
//    }
    
    func getEncoder(for additionalKey: CodingKey?) -> LineEncoderImplementation {
        if let additionalKey = additionalKey {
            var newCodingPath = self.codingPath
            newCodingPath.append(additionalKey)
            return Self(options: self.options, codingPath: newCodingPath)
        }
        
        return self.thisInstance
    }
}





enum EncodedValue: Equatable {
    case string(String)
    case number(String)
    case bool(Bool)
    case null
    
    case array([EncodedValue])
    case object([String: EncodedValue])
}

extension EncodedValue {
    var isValue: Bool {
        switch self {
        case .array, .object:
            return false
        case .null, .number, .string, .bool:
            return true
        }
    }
    
    var isContainer: Bool {
        switch self {
        case .array, .object:
            return true
        case .null, .number, .string, .bool:
            return false
        }
    }
}

extension EncodedValue {
    var debugDataTypeDescription: String {
        switch self {
        case .array:
            return "an array"
        case .bool:
            return "bool"
        case .number:
            return "a number"
        case .string:
            return "a string"
        case .object:
            return "a dictionary"
        case .null:
            return "null"
        }
    }
}


//===----------------------------------------------------------------------===//
// Shared ISO8601 Date Formatter
//===----------------------------------------------------------------------===//

//This package requires recent Swift. No conditional inclusion.
internal var _iso8601Formatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = .withInternetDateTime
    return formatter
}()



//===----------------------------------------------------------------------===//
// Shared Key Types
//===----------------------------------------------------------------------===//
//
//internal struct _PotentialNumericKey: CodingKey {
//    public var stringValue: String
//    public var intValue: Int?
//
//    public init?(stringValue: String) {
//        self.stringValue = stringValue
//        self.intValue = nil
//    }
//
//    public init?(intValue: Int) {
//        self.stringValue = "\(intValue)"
//        self.intValue = intValue
//    }
//
//    public init(stringValue: String, intValue: Int?) {
//        self.stringValue = stringValue
//        self.intValue = intValue
//    }
//
//    internal init(index: Int) {
//        self.stringValue = "Index \(index)"
//        self.intValue = index
//    }
//
//    internal static let `super` = _PotentialNumericKey(stringValue: "super")!
//}
