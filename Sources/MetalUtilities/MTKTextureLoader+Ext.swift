//
//  File.swift
//  MetalUtilities
//
//  Created by David Crooks on 29/07/2025.
//

import Foundation
import MetalKit

enum TextureErrors : Error {
    case cannotLoadTexture
    case cannotFindURL
}
extension MTKTextureLoader {
    public func loadFromBundle(name:String)  throws -> MTLTexture {
        guard let url = Bundle.main.url(forResource: name, withExtension: "png") else {
            throw TextureErrors.cannotFindURL
        }
       
        return try newTexture(URL: url)
    }
}
