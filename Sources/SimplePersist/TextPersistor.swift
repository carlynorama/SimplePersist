import Foundation

public protocol StringPersistable: LosslessStringConvertible, Sendable, Codable {
  //the losses strings can't have \n
  init?(_ description: some StringProtocol)
}

public actor BasicTextPersistor<Element: StringPersistable>: LinePersisting {
  typealias Element = Element
  private let fm = FileManager.default
  private(set) var separator: String
  private(set) var encoding: String.Encoding = .utf8
  let storageUrl: URL

  public init(storageUrl: URL, separator: String = "\n") {
    self.storageUrl = storageUrl
    self.separator = separator
    if !FileIO.fileExists(storageUrl) {
      FileIO.touch(storageUrl)
    }
  }

  private func makeBlob(from array: [StringPersistable]) -> String {
    array.map { $0.description }.joined(separator: separator)
  }

  public func write(contentsOf: [StringPersistable]) throws {
    try makeBlob(from: contentsOf).write(to: storageUrl, atomically: true, encoding: .utf8)
  }

  public func write(contentsOf: [Element]) throws {
    try makeBlob(from: contentsOf).write(to: storageUrl, atomically: true, encoding: .utf8)
  }

  //Do you need appends to be atomic? That is, as supported by the O_APPEND flag for open.
  public func append(_ item: Element) throws {
    if let data = "\(separator)\(item.description)".data(using: encoding) {
      try FileIO.append(data, to: storageUrl)
    } else {
      throw PersistorError.stringNotDataEncodable
    }
  }

  public func append(contentsOf: [Element]) throws {
    if let data = "\(separator)\(makeBlob(from: contentsOf))".data(using: encoding) {
      try FileIO.append(data, to: storageUrl)
    } else {
      throw PersistorError.stringNotDataEncodable
    }
  }

  //this is async for the actor, not the file i/o
  public func retrieve() throws -> [Element] {
    let string = try String(contentsOf: storageUrl)
    return string.split(separator: separator).compactMap({
      Element.init($0)
    })
  }

  public func retrieveAvailable() -> [Element] {
    do {
      return try retrieve()
    } catch {
      return []
    }
  }

  public func clearAll() throws {
    try "".write(to: storageUrl, atomically: true, encoding: .utf8)
  }

  public func lastModified() throws -> Date {
    try FileIO.lastModified(of: storageUrl)
  }

  public func size() throws -> Int {
    try FileIO.size(of: storageUrl)
  }
}
