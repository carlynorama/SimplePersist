import Foundation

//For Apple Platforms
#if canImport(UniformTypeIdentifiers)
  import UniformTypeIdentifiers
#endif

extension FileIO {

  static func loadDataFromFile(urlString: String, limitTypes uttypes: [UTType] = []) throws -> (
    fileName: String, data: Data, mimeType: String
  ) {
    let url = try FileIO.verifyFileURL(string: urlString)
    return try loadData(url: url, limitTypes: uttypes)
  }

  // import SwiftUI
  // func loadImageFromFile(url:URL) throws -> (fileName:String, data:Data, mimeType:String) {
  //     let dataReturn = try loadData(url:url, limitTypes: [.image])
  //     print(dataReturn.mimeType)
  // }

  //URL init must be complete with scheme URL(string:"file:///Users/blah/blah/blah/small_test.png") or
  //or use URL(fileURLWithPath: "small_test.png") initializer.
  static func loadData(url: URL, limitTypes uttypes: [UTType] = []) throws -> (
    fileName: String, data: Data, mimeType: String
  ) {
    if !uttypes.isEmpty {
      print("Test UTType Check")
      guard url.pointsToItemOfType(uttypes: uttypes) else {
        throw FileIOError("MinimalAttachable: Does not conform to allowed types.")
      }
    }

    guard let data = try? Data(contentsOf: url) else {
      throw FileIOError("No data from file at the location given.")
    }
    let mimeType = url.mimeType()
    // let ext = url.pathExtension
    // var leaf = url.lastPathComponent
    // if !ext.isEmpty {
    //     leaf = leaf.split(separator: ".").dropLast().joined(separator: ".") //incase there were other periods in the file name
    // }

    return (fileName: url.lastPathComponent, data: data, mimeType: mimeType)
  }

}
