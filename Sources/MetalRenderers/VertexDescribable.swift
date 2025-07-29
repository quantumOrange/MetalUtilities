//
//  File.swift
//  MetalUtilities
//
//  Created by David Crooks on 29/07/2025.
//

import Foundation
import Metal

public protocol VertexDescribable {
    static func vertexDescriptor(bufferIndex:Int) -> MTLVertexDescriptor
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
    public static func vertexDescriptor(bufferIndex:Int = 0) -> MTLVertexDescriptor {
        let vertexDescriptor = MTLVertexDescriptor()
        
        // Positions.
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = bufferIndex
        
        // Texture coordinates.
        vertexDescriptor.attributes[1].format = .float2
        vertexDescriptor.attributes[1].offset = 8
        vertexDescriptor.attributes[1].bufferIndex = bufferIndex
        
        // Buffer Layout
        vertexDescriptor.layouts[0].stride = 16
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        
        return vertexDescriptor
    }
}


public struct PointVertex {
    let position:SIMD3<Float>
    let size:Float
    let value:Float
    
    public init(position: SIMD3<Float>, size: Float, value: Float) {
        self.position = position
        self.size = size
        self.value = value
    }
}

extension PointVertex : VertexDescribable {
    
    public  static func vertexDescriptor(bufferIndex:Int = 0) -> MTLVertexDescriptor {
        let vertexDescriptor = MTLVertexDescriptor()
        // We have to tell metal what kind of vertex data to expect
        //position
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = MemoryLayout<PointVertex>.offset(of: \PointVertex.position)!
        vertexDescriptor.attributes[0].bufferIndex = bufferIndex
        
        //size
        vertexDescriptor.attributes[1].format = .float
        vertexDescriptor.attributes[1].offset = MemoryLayout<PointVertex>.offset(of: \PointVertex.size)!
        vertexDescriptor.attributes[1].bufferIndex = bufferIndex
        
        //Value
        vertexDescriptor.attributes[2].format = .float
        vertexDescriptor.attributes[2].offset = MemoryLayout<PointVertex>.offset(of: \PointVertex.value)!
        vertexDescriptor.attributes[2].bufferIndex = bufferIndex
        
        //Attribute at index 0 references a buffer at index 0 that has no stride
        vertexDescriptor.layouts[0].stride = MemoryLayout<PointVertex>.stride
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        
        return vertexDescriptor
    }
    
}
