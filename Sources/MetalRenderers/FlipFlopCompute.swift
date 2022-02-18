//
//  File.swift
//  
//
//  Created by David Crooks on 17/02/2022.
//

import Foundation
import Foundation
import Metal
import MetalKit
import simd

fileprivate let maxBuffersInFlight = 3

public actor FlipFlopCompute<Uniforms:Uniforming> {

    let library:MTLLibrary
    var computePipeline:MTLComputePipelineState!
    let commandQueue: MTLCommandQueue
   
    let inFlightSemaphore = DispatchSemaphore(value: maxBuffersInFlight)
    
    var uniformBuffer: MTLBuffer
    var uniformBufferOffset = 0
    var uniformBufferIndex = 0
    var uniforms: UnsafeMutablePointer<Uniforms>
    
    var size:CGSize = CGSize.zero

    var target_0:MTLTexture!
    var target_1:MTLTexture!
    
    public init?(commandQueue:MTLCommandQueue, library:MTLLibrary, device:MTLDevice, initialValue:Uniforms, kernalName:String ) async  {
       
        self.library = library
       
        self.commandQueue = commandQueue
        
        let uniformBufferSize = Uniforms.alignedUniformsSize * maxBuffersInFlight
        
        guard let buffer = device.makeBuffer(length:uniformBufferSize, options:[MTLResourceOptions.storageModeShared]) else { return nil }
        uniformBuffer = buffer
        
        self.uniformBuffer.label = "UniformBuffer"
        
        uniforms = UnsafeMutableRawPointer(uniformBuffer.contents()).bindMemory(to:Uniforms.self, capacity:1)
        
        uniforms.pointee = initialValue
        
        try? createPipelines(device:device,kernalName:kernalName)
    }
    
    func createPipelines(device:MTLDevice,kernalName:String) throws {
        let computeDescriptor = MTLComputePipelineDescriptor()
        computeDescriptor.threadGroupSizeIsMultipleOfThreadExecutionWidth = true
        computeDescriptor.computeFunction = library.makeFunction(name:kernalName)
        
        computePipeline =  try device.makeComputePipelineState(descriptor: computeDescriptor, options: MTLPipelineOption(rawValue: 0), reflection: nil)
    }
    
    func updateUniforms(values:Uniforms) {
        updateDynamicBufferState()
        uniforms.pointee = values
        uniforms.pointee.time =  Float(CACurrentMediaTime())
    }
    
    var startTime:Double = 0
    
    var currentTime:Double {
        CACurrentMediaTime() - startTime
    }
    
    private func updateDynamicBufferState() {
        /// Update the state of our uniform buffers before rendering
        
        uniformBufferIndex = (uniformBufferIndex + 1) % maxBuffersInFlight
        uniformBufferOffset = Uniforms.alignedUniformsSize * uniformBufferIndex
        
        uniforms = UnsafeMutableRawPointer(uniformBuffer.contents() + uniformBufferOffset).bindMemory(to:Uniforms.self, capacity:1)
    }
    
    public func draw(with values:Uniforms, in drawable: CAMetalDrawable? = nil) -> MTLTexture? {
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return nil }
        
        let width = Int(size.width)
        let height = Int(size.height)
       
        guard width > 0, height > 0 else { return nil }
       
        /// Per frame updates hare
        _ = inFlightSemaphore.wait(timeout: DispatchTime.distantFuture)
        
        updateUniforms(values: values)
            
        let threadsPerThreadgroup = MTLSize(width: 8, height: 8, depth: 1);
        let threadgroups = MTLSize(width: (width  + threadsPerThreadgroup.width  - 1) / threadsPerThreadgroup.width,
                                   height: (height + threadsPerThreadgroup.height - 1) / threadsPerThreadgroup.height,
                                   depth: 1);
        
        let computeEncoder = commandBuffer.makeComputeCommandEncoder()!
        
        computeEncoder.setBuffer(uniformBuffer, offset: uniformBufferOffset, index: 0)
        computeEncoder.setTexture(target_0, index: 0)
        computeEncoder.setTexture(target_1, index: 1)
        computeEncoder.setComputePipelineState(computePipeline)
        computeEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadsPerThreadgroup)
        computeEncoder.endEncoding()
        
        if let drawable = drawable {
            let blitEncoder = commandBuffer.makeBlitCommandEncoder()
            blitEncoder?.copy(from:target_1, to: drawable.texture)
            blitEncoder?.endEncoding()
                
            commandBuffer.present(drawable)
        }
        
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        //let duration = commandBuffer.gpuStartTime -  commandBuffer.gpuEndTime
        //print("Compute duration:\(duration)")
    
        inFlightSemaphore.signal()
        
        swap(&target_0,&target_1)
        return target_0
    }
    
    public func drawableSizeWillChange(size:CGSize, pixelFormat:MTLPixelFormat, device:MTLDevice) {
         self.size = size
        
        let width = Int(size.width)
        let height = Int(size.height)
       
         guard width > 0, height > 0 else { return }
         
         let renderTargetDescriptor = MTLTextureDescriptor()
      
         renderTargetDescriptor.pixelFormat = pixelFormat
         renderTargetDescriptor.textureType =  MTLTextureType.type2D
         renderTargetDescriptor.mipmapLevelCount = 4
         renderTargetDescriptor.width = width
         renderTargetDescriptor.height = height
         
         renderTargetDescriptor.usage = [ MTLTextureUsage.shaderRead , MTLTextureUsage.shaderWrite ]
         
         target_0 = device.makeTexture(descriptor:renderTargetDescriptor)!
         target_1 = device.makeTexture(descriptor:renderTargetDescriptor)!
    }
}
