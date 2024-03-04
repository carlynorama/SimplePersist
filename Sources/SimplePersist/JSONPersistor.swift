import Foundation

//:FilePersistorProtocol
public actor JSONPersistor<Element: Codable>:FilePersisting {
  typealias Element = Element
  private let fm = FileManager.default
  private var encoder: JSONEncoder
  private var decoder: JSONDecoder
  let storageUrl: URL

  public init(storageUrl: URL) {
    self.storageUrl = storageUrl

    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    decoder.dateDecodingStrategy = .iso8601

    self.decoder = decoder

    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601

    encoder.outputFormatting = .sortedKeys
    encoder.outputFormatting.formUnion(.withoutEscapingSlashes)
    encoder.outputFormatting.formUnion(.prettyPrinted)

    self.encoder = encoder

    if !FileIO.fileExists(storageUrl) {
      FileIO.touch(storageUrl)
    }
  }

  public func write(contentsOf: [Element]) throws {
    let data = try encoder.encode(contentsOf)
    try data.write(to: storageUrl)
  }

  //this is async for the actor, not the file i/o
  public func retrieve() throws -> [Element] {
    let data = try Data(contentsOf: storageUrl)
    let decoded = try decoder.decode([Element].self, from: data)
    return decoded
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
