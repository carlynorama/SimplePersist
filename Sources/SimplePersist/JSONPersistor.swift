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

struct JSONPersistor {
    
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
        FileIO.makeURL(
            toFileNamed: documentName,
            inFolder: folderName,
            withTimeStamp: withTimeStamp,
            withExtension: ext,
            relativeTo: defaultDirectory)
    }
    
   
    
}


