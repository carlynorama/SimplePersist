#if os(Linux)
  import Foundation

  //https://github.com/apple/swift-corelibs-foundation/blob/36a411b304063de2cbd3fe06adc662e7648d5a9d/Sources/Foundation/URL.swift#L749
  //TODO: isDirectory one, too.
  extension URL {
    public func appending(path: String) -> Self {
      self.appendingPathComponent(path)
    }
  }

#endif
