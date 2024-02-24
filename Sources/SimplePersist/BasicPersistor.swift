//
//  FileIO.swift
//
//
//  Created by Carlyn Maw on 4/19/23.
//  Updated 02/2024
//

//#if os(Linux)
//import Glibc
//#else
//import Darwin.C
//
//#endif

import Foundation

struct BasicPersistor {

  let fm: FileManager
  //let timeStampFormat:String
  //let dateFormatter:DateFormatter
  let defaultDirectory = ""

  init() {
    self.fm = FileManager.default
    // self.timeStampFormat = "YYYYMMdd'T'HHmmss"
    // self.dateFormatter = DateFormatter()
    // self.dateFormatter.dateFormat =  self.timeStampFormat
  }

  //Newer style, check against new Foundation.
  //TODO: Worth it to make formatter for the struct?
  @available(macOS 12.0, *)
  func timeStamp() -> String {
    return Date.now.ISO8601Format()
    //let date = Date.now
    //return dateFormatter.string(from: date)
  }

  @available(macOS 13.0, iOS 16.0, *)
  func urlInDefault(
    toFileNamed documentName: String,
    inFolder folderName: String,
    withTimeStamp: Bool,
    withExtension ext: String
  ) {
    Self.makeURL(
      toFileNamed: documentName,
      inFolder: folderName,
      withTimeStamp: withTimeStamp,
      withExtension: ext,
      relativeTo: defaultDirectory)
  }

  //------------------------------------------------- STATIC
  public static func fileExists(_ path: String) -> Bool {
    FileManager.default.fileExists(atPath: path)
  }

  public static func fileExists(_ url: URL) -> Bool {
    FileManager.default.fileExists(atPath: url.path)
  }

  @discardableResult
  public static func touch(_ url: URL) -> Bool {
    FileManager.default.createFile(atPath: url.path, contents: nil)
  }

  public static func createDirectory(string: String, withSubs: Bool) throws {
    try FileManager.default.createDirectory(
      atPath: string,
      withIntermediateDirectories: withSubs)  //,
    //attributes: [FileAttributeKey : Any]?
  }

  //Old School.
  static func timeStamp(forDate date: Date = Date(), withFormat: String = "YYYYMMdd'T'HHmmss")
    -> String
  {
    let formatter = DateFormatter()
    formatter.dateFormat = withFormat
    return formatter.string(from: date)
  }

  @available(macOS 13.0, iOS 16.0, *)
  static func makeFileURL(filePath: String) -> URL {
    return URL(filePath: filePath)
  }

  @available(macOS 13.0, iOS 16.0, *)
  static func makeURL(
    toFileNamed documentName: String,
    inFolder folderName: String,
    withTimeStamp: Bool,
    withExtension ext: String,
    relativeTo: String
  ) {
    let timeStamp = withTimeStamp ? "" : "_\(timeStamp())"
    if var baseURL = URL(string: relativeTo) {
      baseURL.append(components: folderName, "\(documentName)\(timeStamp)")
      baseURL.appendPathExtension(ext)
    }
  }

  static func write<T: Encodable>(
    _ value: T,
    to url: URL,
    encodedUsing encoder: JSONEncoder = .init()
  ) throws {
    let data = try encoder.encode(value)
    try data.write(to: url)
  }

  static func read<T: Decodable>(
    from url:URL, 
    decoder: JSONDecoder = JSONDecoder()
  ) async throws -> T {
    let data = try Data(contentsOf:url)
    let decoded = try decoder.decode(T.self, from: data)
    return decoded
  }

}


//Feb 2024 Copy/Paste from NSData descriptions.  
//WritingOptions
// static var atomic: NSData.WritingOptions
// An option to write data to an auxiliary file first and then replace the original file with the auxiliary file when the write completes.
// static var withoutOverwriting: NSData.WritingOptions
// An option that attempts to write data to a file and fails with an error if the destination file already exists.
// static var noFileProtection: NSData.WritingOptions
// An option to not encrypt the file when writing it out.
// static var completeFileProtection: NSData.WritingOptions
// An option to make the file accessible only while the device is unlocked.
// static var completeFileProtectionUnlessOpen: NSData.WritingOptions
// An option to allow the file to be accessible while the device is unlocked or the file is already open.
// static var completeFileProtectionUntilFirstUserAuthentication: NSData.WritingOptions
// An option to allow the file to be accessible after a user first unlocks the device.
// static var fileProtectionMask: NSData.WritingOptions
// An option the system uses when determining the file protection options that the system assigns to the data.

//Reading Options
// static var mappedIfSafe: NSData.ReadingOptions
// A hint indicating the file should be mapped into virtual memory, if possible and safe.
// static var uncached: NSData.ReadingOptions
// A hint indicating the file should not be stored in the file-system caches.
// static var alwaysMapped: NSData.ReadingOptions
// Hint to map the file in if possible.
