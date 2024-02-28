//
//  File.swift
//  
//
//  Created by Carlyn Maw on 2/28/24.
//


class LCEncoderData {
    typealias Output = [UInt8]
    var current: LCWIP?
    
    enum LCWIP {
        case value(LCEncodedValue)
        //case encoder(LineEncoderImplementation)
        //case nestedArray([LCWorkInProgress])
        case nestedObject(ObjectBox)
    }
    
    final class ObjectBox {
        //private(set) var dict: [String: LCWorkInProgress] = [:]
        
        private(set) var dict: [Output:LCWIP] = [:]
        init() {
            //self.dict.reserveCapacity(20)
        }
        
        @inline(__always) func set(_ value: LCEncodedValue, for key: Output) {
            self.dict[key] = .value(value)
        }
        
        var values: [Output: LCEncodedValue] {
            self.dict.mapValues { (future) -> LCEncodedValue in
                switch future {
                case .value(let value):
                    return value
                    //                case .nestedArray(let array):
                    //                    return .array(array.values)
                case .nestedObject(let object):
                    return .object(object.values)
//                case .encoder(let encoder):
//                    return encoder.value ?? .object([:])
                }
            }
        }
        
    }

}

