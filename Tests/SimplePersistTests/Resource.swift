//
//  File.swift
//
//
//  Created by Carlyn Maw on 2/24/24.
//

//https://stackoverflow.com/questions/46410832/xctest-load-file-from-disk-without-bundle-on-all-platforms-xcode-spm-mac-linu

//TODO: This is a hack to get around Xcode tests not finding the included resources. Figure out real fix?

import Foundation

struct Resource {
  let name: String
  let type: String
  let url: URL

  init(name: String, type: String, sourceFile: StaticString = #file) throws {
    self.name = name
    self.type = type

    // The following assumes that your test source files are all in the same directory, and the resources are one directory down and over
    // <Some folder>
    //  - Resources
    //      - <resource files>
    //  - <Some test source folder>
    //      - <test case files>
    let testCaseURL = URL(fileURLWithPath: "\(sourceFile)", isDirectory: false)
    let testsFolderURL = testCaseURL.deletingLastPathComponent()
    let resourcesFolderURL = testsFolderURL.deletingLastPathComponent().appendingPathComponent(
      "Resources", isDirectory: true)
    self.url = resourcesFolderURL.appendingPathComponent("\(name).\(type)", isDirectory: false)
  }
}
