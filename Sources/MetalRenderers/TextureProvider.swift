//
//  MetalProtocols.swift
//  TimeWarpVFX
//
//  Created by David Crooks on 23/07/2025.
//

import Foundation
import Metal

public protocol TextureProvider {
    func render(commandBuffer:MTLCommandBuffer,t:Float,dt:Float) -> MTLTexture?
    var target_texture:MTLTexture? { get }
    func drawableSizeWillChange(_ size:CGSize)
}


public enum TextureDestination {
    case fragmentOnly
    case all
    case vertexOnly
    
    var fragment:Bool {
        switch self {
        case .fragmentOnly, .all:
            return true
        case .vertexOnly:
            return false
        }
    }
    
    var vertex:Bool {
        switch self {
        case .fragmentOnly, .all:
            return true
        case .vertexOnly:
            return false
        }
    }
}



public struct TextureWithoutRender:TextureProvider  {
    public func render(commandBuffer: any MTLCommandBuffer,t:Float,dt:Float) -> (any MTLTexture)? {
        target_texture
    }
    
    init( target_texture: MTLTexture) {
        self.target_texture = target_texture
    }
    
    public var target_texture:MTLTexture?
    
    public func drawableSizeWillChange(_ size: CGSize) { }
}

extension MTLTexture {
    public var textureProvider:TextureWithoutRender {
        TextureWithoutRender(target_texture: self)
    }
}

public class WithoutRender :TextureProvider {
    
    public func render(commandBuffer: any MTLCommandBuffer,t:Float,dt:Float) -> (any MTLTexture)? {
        pipeline.target_texture
    }
    
    public init( pipeline: TextureProvider) {
        self.pipeline = pipeline
        
    }
    
    public var target_texture:MTLTexture? { pipeline.target_texture }
    
    var pipeline:TextureProvider
    
    public func drawableSizeWillChange(_ size: CGSize) { }
}


