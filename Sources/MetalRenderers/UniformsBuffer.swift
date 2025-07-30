//
//  File.swift
//  MetalUtilities
//
//  Created by David Crooks on 29/07/2025.
//

import Foundation
import Metal

final class UniformsBuffer<Uniforms> {
    static var alignedUniformsSize: Int {
        (MemoryLayout<Uniforms>.size + 0xFF) & -0x100
    }

    var uniformBuffer: MTLBuffer
    var uniformBufferOffset = 0
    var uniformBufferIndex = 0
    var uniformsPointer: UnsafeMutablePointer<Uniforms>
    
    public var uniforms: Uniforms {
        didSet {
            print("set uniforms")
        }
    }

    public init(device:MTLDevice, initialValue:Uniforms, name:String = "")  {

        let uniformBufferSize = Self.alignedUniformsSize * maxBuffersInFlight
        
        guard let buffer = device.makeBuffer(length:uniformBufferSize, options:[MTLResourceOptions.storageModeShared]) else {  fatalError() }
        uniformBuffer = buffer
        
        self.uniformBuffer.label = "Uniform Buffer \(name)"
        
        uniformsPointer = UnsafeMutableRawPointer(uniformBuffer.contents()).bindMemory(to:Uniforms.self, capacity:1)
        
        uniformsPointer.pointee = initialValue
        uniforms = initialValue
    }
    
    func updateUniforms() {
        updateDynamicBufferState()
        uniformsPointer.pointee = uniforms
    }
   
    private func updateDynamicBufferState() {
        /// Update the state of our uniform buffers before rendering
        
        uniformBufferIndex = (uniformBufferIndex + 1) % maxBuffersInFlight
        uniformBufferOffset = Self.alignedUniformsSize * uniformBufferIndex
        
        uniformsPointer = UnsafeMutableRawPointer(uniformBuffer.contents() + uniformBufferOffset).bindMemory(to:Uniforms.self, capacity:1)
    }
}


