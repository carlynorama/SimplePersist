//this is async for the actor, not the file i/o
//https://forums.swift.org/t/task-safe-way-to-write-a-file-asynchronously/54639/3

import Foundation

enum PersistorError: Error {
  case unknownError(_ message: String)
  case fileAttributeUnavailable(_ attributeName: String)
  case stringNotDataEncodable
}

extension PersistorError {
  init(_ message: String) {
    self = .unknownError(message)
  }
}
