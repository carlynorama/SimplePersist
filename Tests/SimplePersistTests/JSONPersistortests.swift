import Foundation
import XCTest

@testable import SimplePersist

final class JSONPersistorTests: XCTestCase {
    
    struct DemoItem: Codable, Equatable {
        let text: String
        let url: URL
        let creationDate: Date
    }
    
    let demoItems = [
        DemoItem(text: "howdy", url: URL(string: "https://www.howdy.com")!, creationDate: Date(timeIntervalSince1970: 33423243)),
        DemoItem(text: "juniper", url: URL(string: "https://www.juniper.com")!, creationDate: Date(timeIntervalSince1970: 123137851))
    ]
    
    //This test is less useful on Linux where Date's +0000 doesn't seem to be a thing.
    //Linux date doesn't go beyond the second.
    //Move the test up higher just incase the other tests can thread.
      func testLastModified() async throws {
          let fm = FileManager.default
          let demo = try Resource(name: "mockData", type: "json")
          let attribute = try fm.attributesOfItem(atPath: demo.url.path)
          let expectedDate = Date(timeIntervalSince1970: 1708812657.2806296)
          if let date = attribute[FileAttributeKey.modificationDate] as? Date {
              XCTAssertEqual(expectedDate, date, "\(date.timeIntervalSince1970) is not \(expectedDate.timeIntervalSince1970)")
          }
      }
    
    func testInitAndSize() async throws {
        let demo = try Resource(name: "mockData", type: "json")
        //let demo = Bundle.module.url(forResource: "strings", withExtension: "txt")
        let persistor = JSONPersistor<DemoItem>(storageUrl: demo.url)
        let values = try await persistor.retrieve()
        let expected = "DemoItem(text: \"Quote C\", url: https://example.com, creationDate: 2024-02-24 13:12:00 +0000)"
        XCTAssertEqual("\(values[0])", expected, "got \(values[0])")
        
        let fileSize = try await persistor.size()
        XCTAssertEqual(fileSize, 339, "expected 30 got \(String(describing:fileSize))")
    }
    
    func testWriteAndClear() async throws {
        let demo = try Resource(name: "mockData", type: "json")
        let base = demo.url.deletingLastPathComponent()
        let newURL = base.appending(component: "newData.json")
        let persistor = JSONPersistor<DemoItem>(storageUrl: newURL)
        try await persistor.write(contentsOf: demoItems)
        let results = await persistor.retrieveAvailable()
        XCTAssertEqual(results, demoItems, "got \(results)")
        
        let expectedString = """
[
  {
    "creationDate" : "1971-01-22T20:14:03Z",
    "text" : "howdy",
    "url" : "https://www.howdy.com"
  },
  {
    "creationDate" : "1973-11-26T04:57:31Z",
    "text" : "juniper",
    "url" : "https://www.juniper.com"
  }
]
"""
        var retrievedString = try String(contentsOf: newURL)
        XCTAssertEqual(retrievedString, expectedString, "got \(retrievedString)")
        
        try await persistor.clearAll()
        retrievedString = try String(contentsOf: newURL)
        XCTAssertEqual(retrievedString, "", "got \(retrievedString)")
        
        try FileIO.deleteFile(at:newURL)
        XCTAssertFalse(FileIO.fileExists(newURL.path()))
        
    }
}
