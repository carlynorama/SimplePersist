//this is async for the actor, not the file i/o
//https://forums.swift.org/t/task-safe-way-to-write-a-file-asynchronously/54639/3

import Foundation

public protocol StringPersistable:LosslessStringConvertible {
    //the losses strings can't have \n
    init?(_ description: some StringProtocol)
}

//public protocol TextFilePersistable<Element>:Sequence, LosslessStringConvertible
//where Element:StringPersistable {}


enum PersitorError:Error {
    case unknownError(message: String)
    case fileAttributeUnavailable(_ attributeName:String)
    case stringNotDataEncodable
}

public actor TextFilePersistor<Element:StringPersistable> {
    private let fm = FileManager.default
    private(set) var separator:String
    private(set) var encoding:String.Encoding = .utf8
    let storageUrl:URL
    
    public static func fileExists(_ path:String) -> Bool {
        FileManager.default.fileExists(atPath: path)
    }
    
    public static func fileExists(_ url:URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }
    
    @discardableResult
    public static func touch(_ url:URL) -> Bool {
        FileManager.default.createFile(atPath: url.path, contents: nil)
    }
    
    public init(storageUrl: URL, separator:String = "\n") {
        self.storageUrl = storageUrl
        self.separator = separator
        if !Self.fileExists(storageUrl) {
            Self.touch(storageUrl)
        }
    }
    
    private func makeBlob(from array: [StringPersistable]) -> String {
        array.map{ $0.description }.joined(separator: separator)
    }

    public func write(contentsOf: [StringPersistable]) async throws {
        try makeBlob(from:contentsOf).write(to: storageUrl, atomically: true, encoding: .utf8)
    }
    
    
    //Do you need appends to be atomic? That is, as supported by the O_APPEND flag for open.
    public func append(_ item:Element) async throws {
        if let data = "\(separator)\(item.description)".data(using: encoding) {
            try appendData(data: data)
        } else {
            throw PersitorError.stringNotDataEncodable
        }
    }
    
    public func append(contentsOf:[Element]) async throws {
        if let data = "\(separator)\(makeBlob(from: contentsOf))".data(using: encoding) {
           try appendData(data: data)
        } else {
            throw PersitorError.stringNotDataEncodable
        }
    }
    
    private func appendData(data:Data) throws {
        let fileHandle = try FileHandle(forWritingTo: storageUrl)
        fileHandle.seekToEndOfFile()
        fileHandle.write(data)
        fileHandle.closeFile()
    }
    
    //this is async for the actor, not the file i/o
    @available(iOS 16.0, *)
    @available(macOS 13.0, *)
    public func retrieve() async throws -> [Element] {
        let string = try String(contentsOf: storageUrl)
        return string.split(separator: separator).compactMap({
            Element.init($0)
        })
    }
    
    @available(iOS 16.0, *)
    @available(macOS 13.0, *)
    public func retrieveAvailable() async -> [Element] {
        do {
            return try await retrieve()
        } catch {
            return []
        }
    }
    
    public func lastModified() throws -> Date {
        let attribute = try fm.attributesOfItem(atPath: storageUrl.path)
        if let date =  attribute[FileAttributeKey.modificationDate] as? Date {
            return date
        } else {
            throw PersitorError.fileAttributeUnavailable("modificationDate")
        }
    }
    
    //The corresponding value is an NSNumber object containing an unsigned long long.
    //Important
    //If the file has a resource fork, the returned value does not include the size of the resource fork.
    public func size() throws -> Int {
        let attribute = try FileManager.default.attributesOfItem(atPath: storageUrl.path)
        if let size =  attribute[FileAttributeKey.size] as? Int {
            return size 
        } else {
            throw PersitorError.fileAttributeUnavailable("size")
        }
    }
}




//
//    associatedtype Storage: Sequence<Element>
//    var values: Storage { get }
//    //init(_ values:some Sequence<Element>)
//    init(_ values:[Element])
//    static func makeArray(from string:String) -> [Element]
//    
//    func writeAll(to fileURL:URL)
//    init?(contentsOf fileURL:URL)
//
//}
//
//extension TextFilePersistable {
//    var description: String {
//        self.values.map{ $0.description }.joined(separator: "\n")
//    }
//
//    init?(_ description: String) {
//       let tmp = description.split(separator: "\n").compactMap({
//            Element.init($0)
//        })
//       if tmp.isEmpty {
//           return nil
//       } else {
//           self.init(tmp)
//       }
//    }
//
//    static func makeArray(from string:String) -> [Element] {
//        string.split(separator: "\n").compactMap({
//            Element.init($0)
//        })
//    }
//
//    init?(contentsOf fileURL:URL) {
//        guard let string = try? String(contentsOf: fileURL) else {
//            return nil
//        }
//        self.init(string)
//    }
//
//    func writeAll(to fileURL:URL) throws {
//        try description.write(to: fileURL, atomically: true, encoding: .utf8)
//    }
//}
//
//
//public protocol MutableTextFilePersistable:TextFilePersistable where Self:MutableCollection {
//    mutating func updateValues(from fileURL:URL) throws
//    mutating func updateValues(to: some Collection<Element>)
//    mutating func append(from fileURL:URL) throws
//    mutating func append(contentsOf: some Sequence<Element>)
//}
//
//extension MutableTextFilePersistable {
//    mutating func updateValues(from fileURL:URL) throws {
//        let string = try String(contentsOf: fileURL)
//        updateValues(to: Self.makeArray(from:string))
//    }
//
//    mutating func append(from fileURL:URL) throws {
//        let string = try String(contentsOf: fileURL) 
//        append(contentsOf: Self.makeArray(from:string))
//    }
//}
