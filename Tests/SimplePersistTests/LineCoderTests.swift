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
    
    
    struct TestSubStruct:Codable {
        let numeral:Int
        let string:String
    }
    

    func testSingleValues() throws {
        let encoder = LineMaker()

        let toEncodeInt = Int.random(in: Int.min...Int.max)
        let toEncodeText = "hello" //TODO: make random strings to test encodings in a different function.
        let toEncodeBool = Bool.random()
        let toEncodeDouble = Double.random(in: Double.leastNonzeroMagnitude...Double.greatestFiniteMagnitude)
        let toEncodeFloat = Float.random(in: Float.leastNonzeroMagnitude...Float.greatestFiniteMagnitude)
        let toEncodeInt32 = Int32.random(in: Int32.min...Int32.max)
        
        let toEncodeOptionalInt:Int? = nil

        
        let encodedInt = try encoder.encode(toEncodeInt).utf8String
        let encodedText = try encoder.encode(toEncodeText).utf8String
        let encodedBool = try encoder.encode(toEncodeBool).utf8String
        
        let encodedDouble = try encoder.encode(toEncodeDouble).utf8String
        let encodedFloat = try encoder.encode(toEncodeFloat).utf8String
        let encodedInt32 = try encoder.encode(toEncodeInt32).utf8String
        
        let encodedOptionalInt = try encoder.encode(toEncodeOptionalInt).utf8String
        
        XCTAssertEqual(toEncodeInt.description, encodedInt)
        XCTAssertEqual(toEncodeText.description, encodedText)
        XCTAssertEqual(toEncodeBool.description, encodedBool)
        XCTAssertEqual(toEncodeDouble.description, encodedDouble)
        XCTAssertEqual(toEncodeFloat.description, encodedFloat)
        XCTAssertEqual(toEncodeInt32.description, encodedInt32)
        XCTAssertEqual(encoder.nullText, encodedOptionalInt)
        
        
    }
    
    func testSimpleObject() throws {
        //        let sub = TestSubStruct(numeral: 34, string: "world")
                let testItem = TestStruct()
                let encoder = LineMaker()
                let encoded = try encoder.encode(testItem)
                let string = String(bytes: encoded, encoding: .utf8)
                XCTAssertEqual("12.hello", string)
    }
}


fileprivate extension Data {
    var utf8String: String {
        String(bytes: self, encoding: .utf8)!
    }
}
