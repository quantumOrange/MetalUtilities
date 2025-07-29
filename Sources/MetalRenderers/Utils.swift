//
//  File.swift
//  MetalUtilities
//
//  Created by David Crooks on 27/07/2025.
//

import Foundation


enum MetalErrors: Error {
     case cannotBuildBuffer
}



extension Array {
    var byteLength:Int {
        MemoryLayout<Element>.stride * count
    }
    
    var  alignedSize:Int {
        (byteLength + 0xFF) & -0x100
    }
}
