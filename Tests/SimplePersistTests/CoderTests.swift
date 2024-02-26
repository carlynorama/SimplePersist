//
//  File.swift
//  
//
//  Created by Carlyn Maw on 2/25/24.
//

import Foundation
import XCTest

@testable import SimplePersist


final class CodeableStringExample:XCTestCase {
    struct TestStruct:Codable {
        let number:Int
        let text:String
        let sub:TestSubStruct
    }
    
    struct TestSubStruct:Codable {
        let numeral:Int
        let string:String
    }
    
    func testExample() throws {
            let sub = TestSubStruct(numeral: 34, string: "world")
            let testItem = TestStruct(number: 12, text: "hello", sub: sub)
        XCTAssertEqual("12.hello", try DotStringMaker.encode(testItem))
        
    }
    
}


final class CodableRoutingTests: XCTestCase {
    func testExample() throws {
        XCTAssertEqual(try Router.encode(Route.home), "/home")
        XCTAssertEqual(try Router.encode(Route.profile(5)), "/profile/5")
        XCTAssertEqual(try Router.encode(Route.nested(.foo)), "/nested/foo")
        XCTAssertEqual(try Router.encode(Route.nested(nil)), "/nested")
        
        XCTAssertEqual(try Router.decode("/home"), Route.home)
        XCTAssertEqual(try Router.decode("/profile/5"), Route.profile(5))
        XCTAssertEqual(try Router.decode("/nested/foo"), Route.nested(.foo))
        XCTAssertEqual(try Router.decode("/nested"), Route.nested(nil))
    }
}
