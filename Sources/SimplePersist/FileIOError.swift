//
//  File.swift
//
//
//  Created by Carlyn Maw on 2/24/24.
//

import Foundation

enum FileIOError: Error {
  case unknownError(_ message: String)
  case fileAttributeUnavailable(_ attributeName: String)
  case noFileAtURL(_ urlString: String)
}

extension FileIOError {
  init(_ message: String) {
    self = .unknownError(message)
  }
}
