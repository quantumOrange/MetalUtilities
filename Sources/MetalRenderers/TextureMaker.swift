//
//  File.swift
//  MetalUtilities
//
//  Created by David Crooks on 27/07/2025.
//

import Foundation
import Metal

public protocol TextureMaker {
    var device:MTLDevice { get }
    var pixelFormat:MTLPixelFormat { get }
}

public extension TextureMaker {
    func makeTexture(width:Int,height:Int,lable:String? = nil, renderTarget:Bool = false) -> MTLTexture? {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat, width: width, height:height, mipmapped:false)
        
        if renderTarget {
            descriptor.usage =  [ MTLTextureUsage.shaderRead , MTLTextureUsage.shaderWrite,MTLTextureUsage.renderTarget ]
        }
        else {
            descriptor.usage =  [ MTLTextureUsage.shaderRead , MTLTextureUsage.shaderWrite]
           // descriptor.usage =   MTLTextureUsage(rawValue: MTLTextureUsage.shaderWrite.rawValue | MTLTextureUsage.shaderRead.rawValue)
        }
       
        //MTLTextureUsage.renderTarget
        let tex = device.makeTexture(descriptor: descriptor)
        if let lable {
            tex?.label = lable
        }
        return tex
    }
    
    func makeTexture3d(width:Int,height:Int, depth:Int) -> (Int,MTLTexture?) {
        let maxTexDimension = 2048
        
        var w = width
        var h = height
        
        if width >= height {
            if width > maxTexDimension {
                let scale = Float(maxTexDimension) / Float(width)
                w = maxTexDimension
                h = Int(scale * Float(h))
            }
        }
        else {
            if height > maxTexDimension {
                let scale = Float(maxTexDimension) / Float(height)
                h = maxTexDimension
                w = Int(scale * Float(w))
            }
        }
        
        let descriptor = MTLTextureDescriptor()
        
        descriptor.textureType = .type3D
        descriptor.pixelFormat = pixelFormat
        descriptor.width = w
        descriptor.height = h
        descriptor.depth =  depth
        descriptor.usage =   MTLTextureUsage(rawValue: MTLTextureUsage.shaderWrite.rawValue | MTLTextureUsage.shaderRead.rawValue )
        
        var tex:MTLTexture? = device.makeTexture(descriptor: descriptor)
        
        var n = 1
        
        while(tex == nil && n<16) {
    
            n *= 2
            descriptor.depth =  depth / n
           
            tex = device.makeTexture(descriptor: descriptor)
        }
        
        let texSizeWithUnit = ByteCountFormatter.string(fromByteCount: Int64(tex?.allocatedSize ?? 0), countStyle: .memory)
        
        print("n = \(n), depth =  \(descriptor.depth), 3D Texure Size: \(texSizeWithUnit)")
        
        return (n,tex)
    }
}
