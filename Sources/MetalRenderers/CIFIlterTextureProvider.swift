//
//  File.swift
//  MetalUtilities
//
//  Created by David Crooks on 27/07/2025.
//

import Foundation
import AVFoundation
import Metal
import CoreImage
import CoreImage.CIFilterBuiltins

protocol Filter {
    func ciFilter(input:CIImage) -> CIFilter
}

class CIFilterTextureProvider : TextureProvider, TextureMaker {
    
    
    func drawableSizeWillChange(_ size: CGSize) {
        
    }
    
    var target_texture: (any MTLTexture)? //{   input?.target_texture }
    var context:CIContext
    var device:MTLDevice
    var pixelFormat:MTLPixelFormat = .bgra8Unorm
    
    init(filter:Filter,context:CIContext,device:MTLDevice,pixelFormat:MTLPixelFormat = .bgra8Unorm) {
        self.filter = filter
        self.context = context
        self.device = device
        self.pixelFormat = pixelFormat
    }
    
    var filter:Filter
    
    func render(commandBuffer: any MTLCommandBuffer,t: Float, dt: Float) -> (any MTLTexture)? {
        guard let inputTexture = input?.render(commandBuffer: commandBuffer,t:t,dt:dt) else { return nil }
        
        if target_texture == nil {
            target_texture = makeTexture(width: inputTexture.width, height: inputTexture.height)
        }
        
        guard let tex = target_texture else { return nil}
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!

        let ciImageOptions: [CIImageOption: Any] = [
            .colorSpace: colorSpace
        ]
        
        guard let inputImage = CIImage(mtlTexture: inputTexture, options:ciImageOptions) else {
            return nil
        }
        
        let ciFilter = filter.ciFilter(input: inputImage)
        
        guard let filteredImage = ciFilter.outputImage else { return nil }
       
        context.render(filteredImage, to:tex, commandBuffer: commandBuffer, bounds:inputImage.extent, colorSpace:colorSpace)
        
        return target_texture
    }

    
    var input:TextureProvider?
}

