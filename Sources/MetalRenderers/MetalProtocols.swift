//
//  MetalProtocols.swift
//  TimeWarpVFX
//
//  Created by David Crooks on 23/07/2025.
//

import Foundation
import Metal

public protocol TextureProvider {
    func render(commandBuffer:MTLCommandBuffer) -> MTLTexture?
    var target_texture:MTLTexture? { get }
}

public struct TextureWithoutRender:TextureProvider  {
    public func render(commandBuffer: any MTLCommandBuffer) -> (any MTLTexture)? {
        target_texture
    }
    
    init( target_texture: MTLTexture) {
        self.target_texture = target_texture
    }
    
    public var target_texture:MTLTexture?
}

extension MTLTexture {
    public var withoutRender:TextureWithoutRender {
        TextureWithoutRender(target_texture: self)
    }
}

public class WithoutRender :TextureProvider {
    public func render(commandBuffer: any MTLCommandBuffer) -> (any MTLTexture)? {
        pipeline.target_texture
    }
    
    public init( pipeline: TextureProvider) {
        self.pipeline = pipeline
    }
    
    public var target_texture:MTLTexture? { pipeline.target_texture }
    
    var pipeline:TextureProvider
}


