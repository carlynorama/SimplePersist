//
//  File.swift
//
//
//  Created by Carlyn Maw on 2/27/24.
//

import Foundation
import XCTest

@testable import SimplePersist


final class LineCoderTests: XCTestCase {
    struct TestStruct:Codable {
        let int:Int
        let text:String
        let bool:Bool
        let optionalInt:Int?
        let double:Double
        let float:Float
        let int32:Int32
        //let sub:TestSubStruct
        init(int: Int, text: String, bool: Bool, optionalInt: Int?, double: Double, float: Float, int32: Int32) {
            self.int = int
            self.text = text
            self.bool = bool
            self.optionalInt = optionalInt
            self.double = double
            self.float = float
            self.int32 = int32
        }
        
        init() {
            self.int = 12
            self.text = "hello"
            self.bool = true
            self.optionalInt = nil
            self.double = 642.4341
            self.float = 62.12
            self.int32 = 3000
        }
        
    }
    
    struct NestedStruct:Codable {
        let int:Int
        let text:String
        let bool:Bool
        let optionalInt:Int?
        let double:Double
        let float:Float
        let int32:Int32
        let sub:TestSubStruct
        //let sub:TestSubStruct
        init(int: Int, text: String, bool: Bool, optionalInt: Int?, double: Double, float: Float, int32: Int32, sub: TestSubStruct) {
            self.int = int
            self.text = text
            self.bool = bool
            self.optionalInt = optionalInt
            self.double = double
            self.float = float
            self.int32 = int32
            self.sub = sub
        }
        
        init() {
            self.int = 12
            self.text = "hello"
            self.bool = true
            self.optionalInt = nil
            self.double = 642.4341
            self.float = 62.12
            self.int32 = 3000
            self.sub = TestSubStruct(moarText: "This is some text", numeral: 76, string: "world", numeroDuo: 257, intOla: 34324531)
        }
        
    }
    
    
    struct TestSubStruct:Codable {
        let moarText:String
        let numeral:Int
        let string:String
        let numeroDuo: Int16
        let intOla:Int
    }
    
    struct MiniStruct:Codable {
        let numeral:Int
        let string:String
        
        init() {
            self.numeral = 4314124
            self.string = "world"
        }
    }
    
    
    
    func testSingleValues() async throws {
        let encoder = LineCoder()
        
        let toEncodeInt = Int.random(in: Int.min...Int.max)
        let toEncodeText = "hello" //TODO: make random strings to test encodings in a different function.
        let toEncodeBool = Bool.random()
        let toEncodeDouble = Double.random(in: Double.leastNonzeroMagnitude...Double.greatestFiniteMagnitude)
        let toEncodeFloat = Float.random(in: Float.leastNonzeroMagnitude...Float.greatestFiniteMagnitude)
        let toEncodeInt32 = Int32.random(in: Int32.min...Int32.max)
        
        let toEncodeOptionalInt:Int? = nil
        
        
        let encodedInt = try await encoder.encode(toEncodeInt).utf8String
        let encodedText = try await encoder.encode(toEncodeText).utf8String
        let encodedBool = try await encoder.encode(toEncodeBool).utf8String
        
        let encodedDouble = try await encoder.encode(toEncodeDouble).utf8String
        let encodedFloat = try await encoder.encode(toEncodeFloat).utf8String
        let encodedInt32 = try await encoder.encode(toEncodeInt32).utf8String
        
        let encodedOptionalInt = try await encoder.encode(toEncodeOptionalInt)
        
        XCTAssertEqual(toEncodeInt.description, encodedInt)
        XCTAssertEqual(toEncodeText.description, encodedText)
        XCTAssertEqual(toEncodeBool.description, encodedBool)
        XCTAssertEqual(toEncodeDouble.description, encodedDouble)
        XCTAssertEqual(toEncodeFloat.description, encodedFloat)
        XCTAssertEqual(toEncodeInt32.description, encodedInt32)
        XCTAssertEqual(Data(encoder.encoderConfig.nullValueOutput), encodedOptionalInt)
        
        
    }
    
    func testSimpleObject() async throws {
        //        let sub = TestSubStruct(numeral: 34, string: "world")
        let testItem = TestStruct()
        let encoder = LineCoder()
        let encoded = try await encoder.encode(testItem).utf8String
        XCTAssertEqual("[bool:true,double:642.4341,float:62.12,int:12,int32:3000,text:hello]", encoded)
    }
    
    func testNestedObject() async throws {
        let testItem = NestedStruct()
        let encoder = LineCoder()
        
        encoder.encoderConfig.showKeysForContainers = true //the default
        let encoded = try await encoder.encode(testItem).utf8String
        XCTAssertEqual("[bool:true,double:642.4341,float:62.12,int:12,int32:3000,sub:[sub.intOla:34324531,sub.moarText:This is some text,sub.numeral:76,sub.numeroDuo:257,sub.string:world],text:hello]", encoded)
        
        encoder.encoderConfig.showKeysForContainers = false
        let encodedNoKeys = try await encoder.encode(testItem).utf8String
        XCTAssertEqual("[bool:true,double:642.4341,float:62.12,int:12,int32:3000,[sub.intOla:34324531,sub.moarText:This is some text,sub.numeral:76,sub.numeroDuo:257,sub.string:world],text:hello]", encodedNoKeys)
    }
    
    func testArray() async throws {
        let encoder = LineCoder()
        let array = Array(repeating: "howdy", count: 5)
        let encoded = try await encoder.encode(array).utf8String
        let test = """
howdy
howdy
howdy
howdy
howdy
"""
        XCTAssertEqual("howdy\nhowdy\nhowdy\nhowdy\nhowdy", encoded)
        XCTAssertEqual(test, encoded)
        
        let miniStructArray = Array(repeating: MiniStruct(), count: 5)
        let encodedMiniStruct = try await encoder.encode(miniStructArray).utf8String
        XCTAssertEqual("[numeral:4314124,string:world]\n[numeral:4314124,string:world]\n[numeral:4314124,string:world]\n[numeral:4314124,string:world]\n[numeral:4314124,string:world]", encodedMiniStruct)
        
        let intArray = Array(repeating: 34, count: 5)
        let encodedIntArray = try await encoder.encode(intArray).utf8String
        XCTAssertEqual("34\n34\n34\n34\n34", encodedIntArray)
        
        let nestedArray = [[67,98], [2,3,4,5,6], [23,1,2,47732], [9]]
        let encodedNestedArray = try await encoder.encode(nestedArray).utf8String
        XCTAssertEqual("34\n34\n34\n34\n34", encodedNestedArray)
        
        
    }
}


fileprivate extension Data {
    var utf8String: String {
        String(bytes: self, encoding: .utf8)!
    }
}
