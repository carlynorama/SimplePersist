//
//  File.swift
//
//
//  Created by Carlyn Maw on 2/24/24.
//

import Foundation

protocol FilePersisting<Element> {
  associatedtype Element

  func lastModified() async throws -> Date
  func size() async throws -> Int

  func write(contentsOf: [Element]) async throws

  //throws if a problem
  func retrieve() async throws -> [Element]

  //returns empty if a problem
  func retrieveAvailable() async -> [Element]

  func clearAll() async throws

}

//appending is cheap when its lines. Potentially expensive if actually an insertion.
protocol LinePersisting<Element>: FilePersisting {
  associatedtype Element

  func append(_ item: Element) async throws
  func append(contentsOf: [Element]) async throws
}



