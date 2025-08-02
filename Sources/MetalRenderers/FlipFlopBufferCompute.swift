//
//  File.swift
//  MetalUtilities
//
//  Created by David Crooks on 30/07/2025.
//

import Foundation
import Metal


public final class FlipFlopBufferCompute<Uniforms,T> : BufferProvider {
    
    public var buffer: (any MTLBuffer)? { outputBuffer }
    
    
    public let pixelFormat:MTLPixelFormat = .bgra8Unorm
    public let device:MTLDevice
    let library:MTLLibrary
    var computePipeline:MTLComputePipelineState!
    let commandQueue: MTLCommandQueue
    let kernalName:String
    
    let count:Int
    var renderTarget:Bool

    public var input:TextureProvider?
    public var input2:TextureProvider?
    public var input3:TextureProvider?
    public var input4:TextureProvider?

    public var inputBuffer:MTLBuffer?
    public var outputBuffer:MTLBuffer?
    
    var uniforms: UniformsBuffer<Uniforms>
    
    public init(commandQueue:MTLCommandQueue, library:MTLLibrary? = nil, values:[T], initialUniforms:Uniforms, kernalName:String, size:CGSize? = nil, pixelFormat:MTLPixelFormat = .bgra8Unorm,renderTarget:Bool = false) throws   {
       
        self.library = library ?? commandQueue.device.makeDefaultLibrary()!
        self.device = commandQueue.device
        self.commandQueue = commandQueue
        self.renderTarget = renderTarget
        self.uniforms = UniformsBuffer(device:commandQueue.device, initialValue: initialUniforms)
        self.kernalName = kernalName
        
        count = values.count
        inputBuffer = try buildBuffer(device:device,values: values,name:"\(kernalName) A")
        outputBuffer = try buildBuffer(device:device,values: values,name:"\(kernalName) B")
        
        try createPipelines(device:commandQueue.device,kernalName:kernalName)
    }
    
    public func buildBuffer(device:MTLDevice, values:[T],name:String) throws -> MTLBuffer {
        guard let buffer = device.makeBuffer(length:values.byteLength, options:[MTLResourceOptions.storageModeShared]) else { throw MetalErrors.cannotBuildBuffer }

        buffer.label = "\(name) Buffer"
        buffer.contents().copyMemory(from: values, byteCount: values.byteLength)
        return buffer
    }
    
    public func update(uniforms value:Uniforms) {
        uniforms.uniforms = value
    }
    
    func createPipelines(device:MTLDevice,kernalName:String) throws {
        let computeDescriptor = MTLComputePipelineDescriptor()
        computeDescriptor.threadGroupSizeIsMultipleOfThreadExecutionWidth = true
        computeDescriptor.computeFunction = library.makeFunction(name:kernalName)!
        
        computePipeline =  try device.makeComputePipelineState(descriptor: computeDescriptor, options: MTLPipelineOption(rawValue: 0), reflection: nil)
    }

    public func update(commandBuffer: any MTLCommandBuffer,t:Float,dt:Float) -> MTLBuffer? {
        swap(&inputBuffer,&outputBuffer)

        print("compute render \(kernalName)")
       
        uniforms.updateUniforms()
        
        let input_texture = input?.render(commandBuffer: commandBuffer,t:t,dt:dt)
        let input_texture2 = input2?.render(commandBuffer: commandBuffer,t:t,dt:dt)
        let input_texture3 = input3?.render(commandBuffer: commandBuffer,t:t,dt:dt)
        let input_texture4 = input4?.render(commandBuffer: commandBuffer,t:t,dt:dt)
        
        let computeEncoder = commandBuffer.makeComputeCommandEncoder()!
        
        computeEncoder.setBuffer(uniforms.uniformBuffer, offset: uniforms.uniformBufferOffset, index: 0)
        
        
        if let input_texture {
            computeEncoder.setTexture(input_texture, index: 1)
        }
        
        if let input_texture2 {
            computeEncoder.setTexture(input_texture2, index: 2)
        }
        
        if let input_texture3 {
            computeEncoder.setTexture(input_texture3, index: 3)
        }
        
        if let input_texture4 {
            computeEncoder.setTexture(input_texture4, index: 4)
        }
        
        computeEncoder.setBuffer(inputBuffer, offset:0, index: 1)
        computeEncoder.setBuffer(outputBuffer, offset:0, index: 2)
        
        
        computeEncoder.label = "Compute Encoder \(kernalName.capitalized)"
        computeEncoder.setComputePipelineState(computePipeline)
        
        let threads = MTLSize(width: count, height: 1, depth: 1)
        let threadsPerThreadgroup = MTLSize(width: 64, height: 1, depth: 1)
        computeEncoder.dispatchThreads(threads, threadsPerThreadgroup: threadsPerThreadgroup)
        computeEncoder.endEncoding()
        
        return outputBuffer
    }
    
}
