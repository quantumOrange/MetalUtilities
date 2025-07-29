//
//  File.swift
//  MetalUtilities
//
//  Created by David Crooks on 29/07/2025.
//

import Foundation
import Metal

public protocol VertexDescribable {
    static var vertexDescriptor:MTLVertexDescriptor { get }
}

public struct ImageVertex : Codable {
    public init(position:SIMD2<Float>,texCoord:SIMD2<Float>) {
        self.position = position
        self.texCoord = texCoord
    }
    
    public let position:SIMD2<Float>
    public let texCoord:SIMD2<Float>
}

extension ImageVertex : VertexDescribable {
    public static var vertexDescriptor: MTLVertexDescriptor {
        let vertexDescriptor = MTLVertexDescriptor()
        
        // Positions.
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        
        // Texture coordinates.
        vertexDescriptor.attributes[1].format = .float2
        vertexDescriptor.attributes[1].offset = 8
        vertexDescriptor.attributes[1].bufferIndex = 0
        
        // Buffer Layout
        vertexDescriptor.layouts[0].stride = 16
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        
        return vertexDescriptor
    }
}
