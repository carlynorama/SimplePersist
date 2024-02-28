//
//  File.swift
//  
//
//  Created by Carlyn Maw on 2/27/24.
//

import Foundation

//protocol StringConvertibleFloat: FloatingPoint & CustomStringConvertible {}

protocol LineCoderProtocol {
    associatedtype Output
    
    var includeHeaderRow:Bool? { get }
    
    var objectPrefix: Output { get }
    var objectSuffix: Output { get }
    var objectDelimiter: Output { get }
    
    var itemPrefix: Output { get }
    var includeKeyInOutput:Bool { get }
    var keyDelimiter:Output { get }
    var keyValueDivider: Output { get }
    var itemSuffix: Output { get }
    var itemDelimiter: Output { get }
    
    var nullValueOutput:Output { get }
    var trueOutput: Output { get }
    var falseOutput: Output { get }
    var emptyOutput: Output { get }
    
    //Encoding
    var dateWrapper: (Date) async throws -> LCEncodedValue { get }
    var dataWrapper: (Data) async throws -> LCEncodedValue { get }
    var floatWrapper: (any FloatingPoint & CustomStringConvertible) async throws -> LCEncodedValue { get }
    var stringWrapper: (any StringProtocol) async throws -> LCEncodedValue { get }
    var intWrapper: (any FixedWidthInteger) async throws -> LCEncodedValue { get }
    
    //TODO: had trouble with this being async.
    var keyEncoder: (CodingKey) throws -> Output { get }
    var writer: (LCEncodedValue) async throws -> Output { get }
    func encode<T: Encodable>(_: T) async throws -> Output
    
}

//TODO: went from struct to class b/c container could not be mutataing.
//Its from updating the WIP.
struct LMBasic:LineCoderProtocol {
    
    init(codingPath:[CodingKey]) {
        self.codingPath = codingPath
    }
    
    typealias Output = [UInt8]
    var codingPath: [CodingKey]   // for Encoder Conformance
    var userInfo: [CodingUserInfoKey : Any] { [:] } // for Encoder Conformance
    
    var nullValueOutput: [UInt8] = [UInt8]._none
    var trueOutput: [UInt8] = [UInt8]._true
    var falseOutput: [UInt8] = [UInt8]._false
    var emptyOutput: [UInt8] = []
    
    var includeHeaderRow: Bool? = false
    var objectPrefix: [UInt8] = []
    var objectSuffix: [UInt8] = []
    var objectDelimiter: [UInt8] = [UInt8._newline]
    
    var itemPrefix: [UInt8] = []
    var includeKeyInOutput: Bool = true
    var keyValueDivider: [UInt8] = [UInt8._colon]
    var keyDelimiter: [UInt8] = [UInt8._period]
    var itemSuffix: [UInt8] = []
    var itemDelimiter: [UInt8] = [UInt8._comma]

    var dateWrapper: (Date) async throws -> LCEncodedValue { wrapDate }
    var dataWrapper: (Data) async throws -> LCEncodedValue  { wrapData }
    var floatWrapper: (any FloatingPoint & CustomStringConvertible) async throws -> LCEncodedValue { wrapFloat }
    var stringWrapper: (any StringProtocol) async throws -> LCEncodedValue { wrapString }
    var intWrapper: (any FixedWidthInteger) async throws -> LCEncodedValue { wrapInt }
    //TODO: had trouble with this being async.
    var keyEncoder: (CodingKey) throws -> Output { encodeKey }
    
    var writer: (LCEncodedValue) async throws -> Output {
        writeValue
    }
    
    func encode<T: Encodable>(_ value: T) async throws -> Output {
        
        if let stringifiedObject = try await wrapEncodable(value, additionalKey: nil) {
            return try await writer(stringifiedObject)
        }
        else { throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "Top-level \(T.self) did not encode any values.")) }
    }
    
    //MARK: Writer
    func writeValue(_ value: LCEncodedValue) -> [UInt8] {
        var bytes = [UInt8]()
        //options handled
        self.writeValue(value, into: &bytes)
        return bytes
    }
    
    private func writeValue(_ value: LCEncodedValue, into bytes: inout [UInt8]) {
        switch value {
        case .null:
            bytes.append(contentsOf: nullValueOutput)
        case .bool(true):
            bytes.append(contentsOf: trueOutput)
        case .bool(false):
            bytes.append(contentsOf: falseOutput)
        case .string(let encoded):
            bytes.append(contentsOf: encoded)
        case .number(let encoded):
            bytes.append(contentsOf: encoded)
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
            //            if #available(macOS 10.13, *), options.contains(.sortedKeys) {
            //                let sorted = dict.sorted { $0.key.compare($1.key, options: [.caseInsensitive, .diacriticInsensitive, .forcedOrdering, .numeric, .widthInsensitive]) == .orderedAscending }
            //                self.writeObject(sorted, into: &bytes)
            //            } else {
            writeObject(dict, into: &bytes)
            //            }
            //            }
        }
        
        func writeObject<Object: Sequence>(_ object: Object, into bytes: inout Output, depth: Int = 0)
        where Object.Element == (key: Output, value: LCEncodedValue)
        {
            var iterator = object.makeIterator()
            bytes.append(contentsOf:objectPrefix)
            if let (key, value) = iterator.next() {
                if includeKeyInOutput {
                    bytes.append(contentsOf: key)
                    bytes.append(contentsOf: keyValueDivider)
                }
                self.writeValue(value, into: &bytes)
            }
            while let (key, value) = iterator.next() {
                bytes.append(contentsOf:itemDelimiter)
                if includeKeyInOutput {
                    bytes.append(contentsOf: key)
                    bytes.append(contentsOf: keyDelimiter)
                }
                
                self.writeValue(value, into: &bytes)
            }
            bytes.append(contentsOf:objectSuffix)
        }
        
    }
    
    //MARK:THE MESS
    //TODO: Make this less of a mess.
    var value: LCEncodedValue? {
        if let WIP {
            switch WIP {
            case .value(let value):
                return value
            case .nestedObject(let object):
                return .object(object.values)
            }
        } else {
            return nil
        }
    }
    
    var currentData:LCEncoderData = LCEncoderData()
    var WIP:LCEncoderData.LCWIP? {
        get { currentData.current }
        set { currentData.current = newValue } //will this make new one if none? No.
    }
    
    func wrapEncodable<E: Encodable>(_ encodable: E, additionalKey: CodingKey?) async throws -> LCEncodedValue? {
        
        if let additionalKey {
            let encoder = getEncoder(for: additionalKey)
            try encodable.encode(to: encoder)
            return encoder.value
        }
        
        switch encodable {
        case let date as Date:
            return try await dateWrapper(date)
        case let data as Data:
            return try await dataWrapper(data)
        case let number as any FixedWidthInteger:
            return try await intWrapper(number)
        case let url as URL:
            return .string(Output(url.absoluteString.utf8))
        case let decimal as Decimal:
            return .number(Output(decimal.description.utf8))
            //        case let object as _DictionaryIsEncodableMarker:
            //            return try self.wrapObject(object as! [String: Encodable], for: additionalKey)
        case let string as any StringProtocol:
            return try await stringWrapper(string)
        default:
            print("default wrapEncodable happened. \(encodable)")
            let encoder = getEncoder(for: additionalKey)
            try encodable.encode(to: encoder)
            return encoder.value
        }
    }
    
    func wrapDate(_ date:Date) -> LCEncodedValue {
        //TODO: handle additional key.
        return .string(Output(_iso8601Formatter.string(from: date).utf8))
    }
    
    internal var _iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = .withInternetDateTime
        return formatter
    }()
    
    //TODO: This is dumb? Just use the raw bytes?
    func wrapData(_ data:Data) -> LCEncodedValue {
        let base64 = data.base64EncodedString()
        return .string(Output(base64.utf8))
    }
    
    func wrapFloat(_ float:any FloatingPoint & CustomStringConvertible) -> LCEncodedValue {
       var string = float.description
       if string.hasSuffix(".0") {
           string.removeLast(2)
       }
        return .number(Output(string.utf8))
    }
    
    func wrapString(_ string:any StringProtocol) -> LCEncodedValue {
        .string(Output(String(string).utf8))
    }
    
    func wrapInt(_ value:any FixedWidthInteger) -> LCEncodedValue {
        .number(Output(value.description.utf8))
    }
    
    func encodeKey(_ key:CodingKey) throws -> [UInt8] {
        var allKeys = codingPath
        allKeys.append(key)
        if let sep = String(bytes: keyDelimiter, encoding: .utf8) {
            let string = allKeys.compactMap { $0.stringValue }.joined(separator: sep)
            return [UInt8](string.utf8)
        } else {
            throw EncodingError.invalidValue(keyDelimiter, EncodingError.Context(codingPath: allKeys, debugDescription: "Could not encode codingPath to key with delimiter."))
        }
    }

}

final class LineCoder  {
    var encoderConfig: LMBasic = LMBasic(codingPath: [])
    
    typealias Output = [UInt8]
    
    public func encode<T: Encodable>(_ value: T) async throws -> Data {
        Data(try await encoderConfig.encode(value))
    }
}

extension LMBasic:Encoder {
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        //fatalError()
        //return KeyedEncodingContainer(LineEncoderKEC(encoder: self, codingPath: codingPath))
        if let WIP {
            if case let .nestedObject(object) = WIP {
                return KeyedEncodingContainer(LineEncoderKEC(encoderInstance: self, object: object))
            }
        } else {
            currentData.current = .nestedObject(LCEncoderData.ObjectBox())
            if case let .nestedObject(object) = WIP {
                return KeyedEncodingContainer(LineEncoderKEC(encoderInstance: self, object: object))
            }
            
        }
        fatalError()
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        fatalError()
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        return LineEncoderSVEC(encoderInstance: self)
    }
    
    //TODO: See struct -> class problem.
    func getEncoder(for additionalKey: CodingKey?) -> Self {
        if let additionalKey = additionalKey {
            var newCodingPath = self.codingPath
            newCodingPath.append(additionalKey)
            return Self(codingPath: newCodingPath)
        }
        
        return self
    }
    
    
}





//MARK: SingleValueEncoder
private struct LineEncoderSVEC: SingleValueEncodingContainer {
    
    var encoderInstance: LMBasic
    var codingPath: [CodingKey] {
        encoderInstance.codingPath
    }
    
    mutating func encodeNil() throws {
        self.encoderInstance.WIP = .value(.null)
    }
    
    mutating func encode(_ value: Bool) throws {
        self.encoderInstance.WIP = .value(.bool(value))
    }
    
    mutating func encode(_ value: String) throws {
        self.encoderInstance.WIP = .value(encoderInstance.wrapString(value))
    }
    
    mutating func encode(_ value: Double) throws {
        try encodeFloatingPoint(value)
    }
    
    mutating func encode(_ value: Float) throws {
        try encodeFloatingPoint(value)
    }
    
    mutating func encode(_ value: Int) throws {
        try encodeFixedWidthInteger(value)
    }
    
    mutating func encode(_ value: Int8) throws {
        try encodeFixedWidthInteger(value)
    }
    
    mutating func encode(_ value: Int16) throws {
        try encodeFixedWidthInteger(value)
    }
    
    mutating func encode(_ value: Int32) throws {
        try encodeFixedWidthInteger(value)
    }
    
    mutating func encode(_ value: Int64) throws {
        try encodeFixedWidthInteger(value)
    }
    
    mutating func encode(_ value: UInt) throws {
        try encodeFixedWidthInteger(value)
    }
    
    mutating func encode(_ value: UInt8) throws {
        try encodeFixedWidthInteger(value)
    }
    
    mutating func encode(_ value: UInt16) throws {
        try encodeFixedWidthInteger(value)
    }
    
    mutating func encode(_ value: UInt32) throws {
        try encodeFixedWidthInteger(value)
    }
    
    mutating func encode(_ value: UInt64) throws {
        try encodeFixedWidthInteger(value)
    }
    
    mutating func encode<T>(_ value: T) throws where T : Encodable {
        fatalError()
    }
    
    
}

extension LineEncoderSVEC {
    @inline(__always) private mutating func encodeFixedWidthInteger<N: FixedWidthInteger>(_ value: N) throws {
        //self.preconditionCanEncodeNewValue()
        self.encoderInstance.WIP = .value(encoderInstance.wrapInt(value))
    }
    
    @inline(__always) private mutating func encodeFloatingPoint<F: FloatingPoint & CustomStringConvertible>(_ float: F) throws {
        //self.preconditionCanEncodeNewValue()
        self.encoderInstance.WIP = .value(encoderInstance.wrapFloat(float))
    }
}



fileprivate struct LineEncoderKEC<Key: CodingKey>: KeyedEncodingContainerProtocol {
    var codingPath: [CodingKey] {
        encoderInstance.codingPath
    }
    
    
    var encoderInstance: LMBasic
    var object:LCEncoderData.ObjectBox

    private func _converted(_ key: Key) throws -> LMBasic.Output {
        try encoderInstance.keyEncoder(key)
    }
    
    mutating func encodeNil(forKey key: Key) throws {
        self.object.set(.null, for: try self._converted(key))
    }
    
    mutating func encode(_ value: Bool, forKey key: Key) throws {
        self.object.set(.bool(value), for: try self._converted(key))
    }
    
    mutating func encode(_ value: String, forKey key: Key) throws {
        self.object.set(encoderInstance.wrapString(value), for: try self._converted(key))
    }
    
    mutating func encode(_ value: Double, forKey key: Key) throws {
        try encodeFloatingPoint(value, key: key)
    }
    
    mutating func encode(_ value: Float, forKey key: Key) throws {
        try encodeFloatingPoint(value, key: key)
    }
    
    mutating func encode(_ value: Int, forKey key: Key) throws {
        try encodeFixedWidthInteger(value, key: key)
    }
    
    mutating func encode(_ value: Int8, forKey key: Key) throws {
        try encodeFixedWidthInteger(value, key: key)
    }
    
    mutating func encode(_ value: Int16, forKey key: Key) throws {
        try encodeFixedWidthInteger(value, key: key)
    }
    
    mutating func encode(_ value: Int32, forKey key: Key) throws {
        try encodeFixedWidthInteger(value, key: key)
    }
    
    mutating func encode(_ value: Int64, forKey key: Key) throws {
        try encodeFixedWidthInteger(value, key: key)
    }
    
    mutating func encode(_ value: UInt, forKey key: Key) throws {
        try encodeFixedWidthInteger(value, key: key)
    }
    
    mutating func encode(_ value: UInt8, forKey key: Key) throws {
        try encodeFixedWidthInteger(value, key: key)
    }
    
    mutating func encode(_ value: UInt16, forKey key: Key) throws {
        try encodeFixedWidthInteger(value, key: key)
    }
    
    mutating func encode(_ value: UInt32, forKey key: Key) throws {
        try encodeFixedWidthInteger(value, key: key)
    }
    
    mutating func encode(_ value: UInt64, forKey key: Key) throws {
        try encodeFixedWidthInteger(value, key: key)
    }
    
    mutating func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
        fatalError()
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        fatalError()
    }
    
    mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        fatalError()
    }
    
    mutating func superEncoder() -> Encoder {
        fatalError()
    }
    
    mutating func superEncoder(forKey key: Key) -> Encoder {
        fatalError()
    }
    
    
}

extension LineEncoderKEC {
    @inline(__always) private mutating func encodeFloatingPoint<F: FloatingPoint & CustomStringConvertible>(_ float: F, key: Key) throws {
        self.object.set(encoderInstance.wrapFloat(float), for:try _converted(key))
    }
    
    @inline(__always) private mutating func encodeFixedWidthInteger<N: FixedWidthInteger>(_ value: N, key: Key) throws {
        self.object.set(encoderInstance.wrapInt(value), for: try _converted(key))
    }
}
