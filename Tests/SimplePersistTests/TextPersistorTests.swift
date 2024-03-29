import Foundation
import XCTest

@testable import SimplePersist

extension String: StringPersistable {
  public init?(_ description: some StringProtocol) {
    self = String(description)
  }
}

final class TextPersistorTests: XCTestCase {

  //This test is less useful on Linux where Date's +0000 doesn't seem to be a thing.
  //Linux date doesn't go beyond the second.
  //Move the test up higher just incase the other tests can thread.
  func testLastModified() async throws {
    let before = Date.now
    //for linux no sub second resolution. (1/2 a second)
    try await Task.sleep(nanoseconds: 500_000_000)
    let bundlePath = Bundle.module.bundleURL
    let demo = bundlePath.appending(path: "modifiedDemo.txt")
    let persistor = BasicTextPersistor<String>(storageUrl: demo)
    try await persistor.write(contentsOf: ["this", "is", "how the", "world", "ends"])
    let modDate = try await persistor.lastModified()
    XCTAssertLessThan(before, modDate, "\(before) was not before \(modDate)")
    //for linux no sub second resolution. (1/2 a second)
    try await Task.sleep(nanoseconds: 500_000_000)
    let after = Date.now
    XCTAssertLessThan(modDate, after, "\(after) was not after \(modDate)")
  }

  func testInit() async throws {
    let demo = try Resource(name: "strings", type: "txt")
    //let demo = Bundle.module.url(forResource: "strings", withExtension: "txt")
    let persistor = BasicTextPersistor<String>(storageUrl: demo.url)
    let values = try await persistor.retrieve()
    XCTAssertEqual(values[0], "hello", "expected hello, got \(values[0])")
  }

  func testMakeBlob() async throws {
    let bundlePath = Bundle.module.bundleURL
    let demo = bundlePath.appending(path: "blobDemo.txt")
    let persistor = BasicTextPersistor<String>(storageUrl: demo)
    try await persistor.write(contentsOf: ["this", "is", "how the", "world", "ends"])
    let values = await persistor.retrieveAvailable()
    XCTAssertEqual(values[3], "world", "expected world, got \(values[3])")
  }

  func testAppendBlob() async throws {
    let bundlePath = Bundle.module.bundleURL
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
    let bundlePath = Bundle.module.bundleURL
    let demo = bundlePath.appending(path: "appendItemDemo.txt")
    let persistor = BasicTextPersistor<String>(storageUrl: demo)
    try await persistor.write(contentsOf: ["this", "is", "how the", "world", "ends"])
    let values = try await persistor.retrieve()
    XCTAssertEqual(values[3], "world", "expected world, got \(values[3])")
    try await persistor.append("... with chex mix!")
    let moarVals = await persistor.retrieveAvailable()
    XCTAssertEqual(
      moarVals[5], "... with chex mix!", "expected chex mix, got \(moarVals[5]). \(moarVals)")
  }

  func testSize() async throws {
    let demo = try Resource(name: "strings", type: "txt")
    //let demo = Bundle.module.url(forResource: "strings", withExtension: "txt")!
    let persistor = BasicTextPersistor<String>(storageUrl: demo.url)
    let fileSize = try await persistor.size()
    XCTAssertEqual(fileSize, 30, "expected 30 got \(String(describing:fileSize))")
  }
}
