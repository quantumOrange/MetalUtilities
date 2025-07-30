//
//  File.swift
//  MetalUtilities
//
//  Created by David Crooks on 27/07/2025.
//

import Foundation
import Metal
import MetalKit

public protocol BufferProvider {
    func update(commandBuffer:MTLCommandBuffer) -> MTLBuffer?
    var  buffer:MTLBuffer? { get }
}

public protocol VertexBuffer:BufferProvider {
    var start:Int { get }
    var count:Int { get }
    var type:MTLPrimitiveType { get }
}

public final class ConstantBuffer<T> : VertexBuffer {
    
    public let start:Int  = 0
    public let count:Int
    public var type:MTLPrimitiveType   = .point
    
    
    public func update(commandBuffer: any MTLCommandBuffer) -> MTLBuffer? {
        guard let buffer = self.buffer else { return nil }
        return buffer
    }
    
    public var buffer: (any MTLBuffer)?
    var lable:String?
    public init(device:MTLDevice,values:[T], lable:String? = nil) throws {
        count = values.count
        buffer = try buildBuffer(device:device,values: values)
    }
    
    public func buildBuffer(device:MTLDevice, values:[T]) throws -> MTLBuffer {
        guard let buffer = device.makeBuffer(length:values.byteLength, options:[MTLResourceOptions.storageModeShared]) else { throw MetalErrors.cannotBuildBuffer }

        buffer.label = "\(lable ?? "Constant") Buffer"
        buffer.contents().copyMemory(from: values, byteCount: values.byteLength)
        return buffer
    }
}

public final class UpdatableBuffer<T> : BufferProvider {
    var bufferIndex : Int = 0
    var values:[T]
    var maxValues:Int
    
    public var buffers: [MTLBuffer] = []
    public var buffer:MTLBuffer? { self.buffers[bufferIndex] }
    
    public func update(commandBuffer: any MTLCommandBuffer) -> MTLBuffer? {
        updateDynamicBufferState()
        return self.buffers[bufferIndex] 
    }
    
    let device:MTLDevice
    var lable:String?
    
    public init(device:MTLDevice,values:[T], lable:String? = nil, capacity:Int = 1024) throws {
        self.device = device
        self.values = values
        maxValues = capacity
        try buildBuffers(device:device,values: values)
    }
    
    private func updateDynamicBufferState() {
        /// Update the state of our uniform buffers before rendering
        bufferIndex = (bufferIndex + 1) % maxBuffersInFlight
        updateBuffer(at: bufferIndex)
    }
    
    private func updateBuffer(at index:Int) {
       
        while values.count > maxValues {
            maxValues *= 2
        }
        
        let currentBuffer =  buffers[index]
        let bufferSize = MemoryLayout<T>.stride * maxValues
        
        if currentBuffer.length < bufferSize {
            buffers[index] = device.makeBuffer(length: bufferSize , options: [MTLResourceOptions.storageModeShared])!
        }
        
        buffers[index].contents().copyMemory(from: values, byteCount: values.byteLength)
    }
    
    private func buildBuffers(device:MTLDevice, values:[T]) throws  {
        while values.count > maxValues {
            maxValues *= 2
        }
        
        for i in 0..<maxBuffersInFlight {
            guard let buffer = device.makeBuffer(length:values.byteLength, options:[MTLResourceOptions.storageModeShared]) else { throw MetalErrors.cannotBuildBuffer }

            buffer.label = "\(lable ?? "Updatable") Buffer \(i)"
            buffer.contents().copyMemory(from: values, byteCount: values.byteLength)
            buffers[i] = buffer
        }
    }
}
