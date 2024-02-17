import XCTest
import Foundation
@testable import SimplePersist

extension String:StringPersistable {
    public init?(_ description:some StringProtocol) {
        self = String(description)
    }
}

final class SimplePersistTests: XCTestCase {
    let file = Bundle.main.url(forResource: "lines", withExtension: "txt")

    func testTouch() {

        //let bundlePath = URL(filePath: Bundle.module.bundlePath)
                                                        // .deletingLastPathComponent()
                                                        // .path()

         let bundlePath =  URL(filePath: Bundle.module.bundlePath) 
            let toTouch = bundlePath.appending(path: "touch.txt")
            BasicTextPersistor<String>.touch(toTouch)
        
        let demo = Bundle.module.url(forResource: "empty", withExtension: "txt")
        XCTAssertNotNil(demo, "demo file not found \(String(describing:demo))")

        let exists = Bundle.module.url(forResource: "touch", withExtension: "txt")
        XCTAssertNotNil(exists, "touched file not found \(String(describing:exists))")
    }

    func testInit() async throws {
        let demo = Bundle.module.url(forResource: "strings", withExtension: "txt") 
        let persistor = BasicTextPersistor<String>(storageUrl: demo!)
        let values = try await persistor.retrieve()
        XCTAssertEqual(values[0], "hello", "expected hello, got \(values[0])")
    }

    func testMakeBlob() async throws {
        let bundlePath =  URL(filePath: Bundle.module.bundlePath) 
        let demo = bundlePath.appending(path: "blobDemo.txt")
        let persistor = BasicTextPersistor<String>(storageUrl: demo)
        try await persistor.write(contentsOf: ["this", "is", "how the", "world", "ends"])
        let values = await persistor.retrieveAvailable()
        XCTAssertEqual(values[3], "world", "expected world, got \(values[3])")
    }

    func testAppendBlob() async throws {
        let bundlePath =  URL(filePath: Bundle.module.bundlePath) 
        let demo = bundlePath.appending(path: "appendBlobDemo.txt")
        let persistor = BasicTextPersistor<String>(storageUrl: demo)
        try await persistor.write(contentsOf: ["this", "is", "how the", "world", "ends"])
        let values = try await persistor.retrieve()
        XCTAssertEqual(values[3], "world", "expected world, got \(values[3])")
        try await persistor.append(contentsOf: ["not with", "a bang", "but a", "whimper"])
        let moarVals = await persistor.retrieveAvailable()
        XCTAssertEqual(moarVals[7], "but a", "expected world, got \(moarVals[7]). \(moarVals)")
    }

    func testAppendItem() async throws {
        let bundlePath =  URL(filePath: Bundle.module.bundlePath) 
        let demo = bundlePath.appending(path: "appendItemDemo.txt")
        let persistor = BasicTextPersistor<String>(storageUrl: demo)
        try await persistor.write(contentsOf: ["this", "is", "how the", "world", "ends"])
        let values = try await persistor.retrieve()
        XCTAssertEqual(values[3], "world", "expected world, got \(values[3])")
        try await persistor.append("... with chex mix!")
        let moarVals = await persistor.retrieveAvailable()
        XCTAssertEqual(moarVals[5], "... with chex mix!", "expected chex mix, got \(moarVals[5]). \(moarVals)")
    }

    func testLastModified() async throws {
        let before = Date.now
        let bundlePath =  URL(filePath: Bundle.module.bundlePath) 
        let demo = bundlePath.appending(path: "modifiedDemo.txt")
        let persistor = BasicTextPersistor<String>(storageUrl: demo)
        try await persistor.write(contentsOf: ["this", "is", "how the", "world", "ends"])
        let modDate = try await persistor.lastModified()
        XCTAssertLessThan(before, modDate, "\(before) was not before \(modDate)")
        let after = Date.now 
        XCTAssertLessThan(modDate, after,"\(after) was not after \(modDate)")
    }

    func testSize() async throws {
        let demo = Bundle.module.url(forResource: "strings", withExtension: "txt")!
        let persistor = BasicTextPersistor<String>(storageUrl: demo)
        let fileSize = try await persistor.size()
        XCTAssertEqual(fileSize, 30, "expected 30 got \(String(describing:fileSize))")
    }
}
