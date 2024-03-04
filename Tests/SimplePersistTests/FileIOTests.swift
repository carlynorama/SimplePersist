//
//  FileIOTests.swift
//
//
//  Created by Carlyn Maw on 2/24/24.
//

import Foundation
import XCTest

@testable import SimplePersist

final class FileIOTests: XCTestCase {

  //This test is less useful on Linux where Date's +0000 doesn't seem to be a thing.
  //Linux date doesn't go beyond the second.
  //Move the test up higher just incase the other tests can thread.

  func testExists() throws {
    let demo = try Resource(name: "strings", type: "txt").url
    XCTAssert(FileIO.fileExists(demo.path()), "\(demo.absoluteString) path not found")
    XCTAssert(FileIO.fileExists(demo), "\(demo.absoluteString) url not found")
  }

  func testTouch() throws {
    //let bundlePath = Bundle.module.bundleURL
    // .deletingLastPathComponent()
    // .path()
    let bundlePath = Bundle.module.bundleURL
    let toTouch = bundlePath.appending(path: "touch.txt")
    FileIO.touch(toTouch)

    let exists = FileIO.fileExists(toTouch.path())
    XCTAssert(exists, "\(toTouch.absoluteString) not found")
  }

  func testCreateDirectory() throws {
    let bundlePath = Bundle.module.bundleURL
    let folders = ["hello", "world", "soMany", "folders"]
    let toMake = bundlePath.appending(
      components: folders.randomElement()!, folders.randomElement()!, folders.randomElement()!)
    try FileIO.createDirectory(string: toMake.path, withSubs: true)
    let toTouch = toMake.appending(component: "fileName.txt")

    FileIO.touch(toTouch)
    let exists = FileIO.fileExists(toTouch.path())
    XCTAssert(exists, "\(toTouch.absoluteString) not found")

  }

  func testTimeStamps() {
    let string = FileIO.timeStamp()
    let string2 = FileIO.timeStamp(forDate: Date.now)
    XCTAssertEqual(string, string2)
  }

  //------- Skiping verifyURL and MakeURL. super trivial.

  struct DemoItem: Codable {
    let text: String
    let url: URL
    let creationDate: Date
  }

  func testBasicReadingWriting() async throws {
    let decoder = JSONDecoder()
    //decoder.keyDecodingStrategy = .convertFromSnakeCase
    decoder.dateDecodingStrategy = .iso8601
    let demo = try Resource(name: "mockData", type: "json").url
    let test: [DemoItem] = try await FileIO.read(from: demo, decoder: decoder)
    XCTAssertEqual(test[0].url, test[2].url, "\(test)")

    let newURL = Bundle.module.bundleURL.appending(component: FileIO.timeStamp())
      .appendingPathExtension("json")

    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601

    encoder.outputFormatting = .sortedKeys
    encoder.outputFormatting.formUnion(.withoutEscapingSlashes)
    encoder.outputFormatting.formUnion(.prettyPrinted)

    try FileIO.write(test, to: newURL, encodedUsing: encoder)

    let orig = try String(contentsOf: demo)
    let new = try String(contentsOf: newURL)

    XCTAssertEqual(
      orig.trimmingCharacters(in: .whitespacesAndNewlines),
      new.trimmingCharacters(in: .whitespacesAndNewlines), "\(newURL.absoluteString)")
  }

  func testDataAppend() throws {
    //Sometimes, When the Light BY LISEL MUELLER
    let partOne = """
      Sometimes, when the light strikes at odd angles
      and pulls you back into childhood
       
      and you are passing a crumbling mansion
      completely hidden behind old willows
       
      or an empty convent guarded by hemlocks
      and giant firs standing hip to hip,
      """
    let partTwo = """
       
      you know again that behind that wall,
      under the uncut hair of the willows
       
      something secret is going on,
      so marvelous and dangerous
       
      that if you crawled through and saw,
      you would die, or be happy forever.
      """

    let newURL = Bundle.module.bundleURL.appending(component: FileIO.timeStamp())
      .appendingPathExtension("txt")

    try partOne.data(using: .utf8)?.write(to: newURL)
    try FileIO.append(partTwo.data(using: .utf8)!, to: newURL)

    let recovered = try String(contentsOf: newURL)

    XCTAssertEqual(recovered, "\(partOne)\(partTwo)")

  }

  //These use FileIO's function under the hood.
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

  func testSize() async throws {
    let demo = try Resource(name: "strings", type: "txt").url
    //let demo = Bundle.module.url(forResource: "strings", withExtension: "txt")!
    let persistor = BasicTextPersistor<String>(storageUrl: demo)
    let fileSize = try await persistor.size()
    XCTAssertEqual(fileSize, 30, "expected 30 got \(String(describing:fileSize))")
  }
}
