import Foundation

#if canImport(UniformTypeIdentifiers)
  import UniformTypeIdentifiers
#endif

extension NSURL {
  public func mimeType() -> String {
    guard let pathExtension else {
      return "application/octet-stream"
    }
    if let mimeType = UTType(filenameExtension: pathExtension)?.preferredMIMEType {
      return mimeType
    } else {
      return "application/octet-stream"
    }
  }
}

extension URL {
  public func mimeType() -> String {
    return UTType(filenameExtension: self.pathExtension)?.preferredMIMEType
      ?? "application/octet-stream"
  }
}

extension URL {
  public func contains(_ uttype: UTType) -> Bool {
    return UTType(mimeType: self.mimeType())?.conforms(to: uttype) ?? false
  }

  public func pointsToItemOfType(uttypes: [UTType]) -> Bool {
    guard let mytype = UTType(mimeType: self.mimeType()) else {
      print("false")
      return false
    }
    for t in uttypes {
      if mytype.conforms(to: t) {
        print("true")
        return true
      }
    }
    print("false")
    return false

  }
}

extension NSString {
  public func mimeType() -> String {
    if let mimeType = UTType(filenameExtension: self.pathExtension)?.preferredMIMEType {
      return mimeType
    } else {
      return "application/octet-stream"
    }
  }
}

extension String {
  public func mimeType() -> String {
    return (self as NSString).mimeType()
  }
}
