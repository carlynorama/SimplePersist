//
//  File.swift
//  
//
//  Created by Carlyn Maw on 2/28/24.
//

import Foundation



enum LCEncodedValue: Equatable {
    typealias Output = [UInt8]
    
    case string(Output)
    case number(Output)
    case bool(Bool)
    case null
    
    case array([LCEncodedValue])
    case object([Output: LCEncodedValue])
}

extension LCEncodedValue {
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

extension LCEncodedValue {
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


//
////MARK: Writer
//extension LCEncodedValue {
//    struct Writer {
//        let options: LineMaker.OutputFormatting
//        
//        func writeValue(_ value: LCEncodedValue) -> [UInt8] {
//            var bytes = [UInt8]()
//            //options handled
//            self.writeValue(value, into: &bytes)
//            return bytes
//        }
//        
//        private func writeValue(_ value: LCEncodedValue, into bytes: inout [UInt8]) {
//            switch value {
//            case .null:
//                bytes.append(contentsOf: options.constants.nullText)
//            case .bool(true):
//                bytes.append(contentsOf: [UInt8]._true)
//            case .bool(false):
//                bytes.append(contentsOf: [UInt8]._false)
//            case .string(let string):
//                bytes.append(contentsOf: string.utf8)
//                //JSON needs some specific stuff see Line 1109 in JSONEncoder.swift
//                //self.encodeString(string, to: &bytes)
//            case .number(let string):
//                bytes.append(contentsOf: string.utf8)
//            case .array(let array):
//                fatalError()
//                //                        var iterator = array.makeIterator()
//                //                        bytes.append(._openbracket)
//                //                        // we don't like branching, this is why we have this extra
//                //                        if let first = iterator.next() {
//                //                            self.writeValue(first, into: &bytes)
//                //                        }
//                //                        while let item = iterator.next() {
//                //                            bytes.append(._comma)
//                //                            self.writeValue(item, into:&bytes)
//                //                        }
//                //                        bytes.append(._closebracket)
//            case .object(let dict):
//                //                fatalError()
//                //            if #available(macOS 10.13, *), options.contains(.sortedKeys) {
//                //                let sorted = dict.sorted { $0.key.compare($1.key, options: [.caseInsensitive, .diacriticInsensitive, .forcedOrdering, .numeric, .widthInsensitive]) == .orderedAscending }
//                //                self.writeObject(sorted, into: &bytes)
//                //            } else {
//                writeObject(dict, into: &bytes)
//                //            }
//                //            }
//            }
//            
//            func writeObject<Object: Sequence>(_ object: Object, into bytes: inout [UInt8], depth: Int = 0)
//            where Object.Element == (key: String, value: LCEncodedValue)
//            {
//                var iterator = object.makeIterator()
//                bytes.append(._openbrace)
//                if let (key, value) = iterator.next() {
//                    //self.encodeString(key, to: &bytes)
//                    bytes.append(contentsOf: key.utf8)
//                    bytes.append(._colon)
//                    self.writeValue(value, into: &bytes)
//                }
//                while let (key, value) = iterator.next() {
//                    bytes.append(._comma)
//                    // key
//                    //self.encodeString(key, to: &bytes)
//                    bytes.append(contentsOf: key.utf8)
//                    bytes.append(._colon)
//                    
//                    self.writeValue(value, into: &bytes)
//                }
//                bytes.append(._closebrace)
//            }
//            
//        }
//    }
//}
