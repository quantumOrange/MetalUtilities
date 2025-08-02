//
//  File.swift
//  MetalUtilities
//
//  Created by David Crooks on 30/07/2025.
//

import Foundation
import Metal

public final class FlipFlopTextureCompute<Uniforms>: TextureProvider,TextureMaker {
    public let pixelFormat:MTLPixelFormat
    public let device:MTLDevice
    let library:MTLLibrary
    var computePipeline:MTLComputePipelineState!
    let commandQueue: MTLCommandQueue
    let kernalName:String
   
    var renderTarget:Bool
    
    public var target_texture:MTLTexture? { input }
    
    public var output:MTLTexture!
    public var input:MTLTexture!
    
    public var input2:TextureProvider?
    public var input3:TextureProvider?
    public var input4:TextureProvider?
   
    public var bufferProvider1:BufferProvider?
    public var bufferProvider2:BufferProvider?
    
    public init?(commandQueue:MTLCommandQueue, library:MTLLibrary,input:MTLTexture, initialValue:Uniforms, kernalName:String, size:CGSize? = nil, renderTarget:Bool = false)   {
        pixelFormat = input.pixelFormat
        self.library = library
        self.device = commandQueue.device
        self.commandQueue = commandQueue
        self.renderTarget = renderTarget
        self.input = input
        self.uniforms = UniformsBuffer(device:commandQueue.device, initialValue: initialValue)
        self.kernalName = kernalName
        
        try? createPipelines(device:commandQueue.device,kernalName:kernalName)
        
        
        
        self.output =  makeTexture(width:input.width, height: input.height,lable: "Target \(kernalName.capitalized)",renderTarget: renderTarget)!
    }
    
    func createPipelines(device:MTLDevice,kernalName:String) throws {
        let computeDescriptor = MTLComputePipelineDescriptor()
        computeDescriptor.threadGroupSizeIsMultipleOfThreadExecutionWidth = true
        computeDescriptor.computeFunction = library.makeFunction(name:kernalName)!
        
        computePipeline =  try device.makeComputePipelineState(descriptor: computeDescriptor, options: MTLPipelineOption(rawValue: 0), reflection: nil)
    }
    
    public func update(uniforms value:Uniforms) {
        uniforms.uniforms = value
    }

    var uniforms: UniformsBuffer<Uniforms>
   
    public func render(commandBuffer:MTLCommandBuffer,t:Float,dt:Float) -> MTLTexture? {
        defer {
            swap(&output,&input)
        }
       // guard let target_texture else { return nil }
        let width = output.width
        let height = output.height
        //let width = Int(size.width)
        //let height = Int(size.height)
        print("compute render \(kernalName)")
        guard width > 0, height > 0 else { print("size zero!!"); return nil }
        
        uniforms.updateUniforms()
            
        let threadsPerThreadgroup = MTLSize(width: 8, height: 8, depth: 1);
        let threadgroups = MTLSize(width: (width  + threadsPerThreadgroup.width  - 1) / threadsPerThreadgroup.width,
                                   height: (height + threadsPerThreadgroup.height - 1) / threadsPerThreadgroup.height,
                                   depth: 1);
        
        //let input_texture = input?.render(commandBuffer: commandBuffer)
        let input_texture2 = input2?.render(commandBuffer: commandBuffer,t:t,dt:dt) 
        let input_texture3 = input3?.render(commandBuffer: commandBuffer,t:t,dt:dt) 
        let input_texture4 = input4?.render(commandBuffer: commandBuffer,t:t,dt:dt) 
        
        let buffer1 = bufferProvider1?.update(commandBuffer: commandBuffer,t:t,dt:dt)
        let buffer2 = bufferProvider2?.update(commandBuffer: commandBuffer,t:t,dt:dt)
      
        let computeEncoder = commandBuffer.makeComputeCommandEncoder()!
        
        computeEncoder.setBuffer(uniforms.uniformBuffer, offset: uniforms.uniformBufferOffset, index: 0)
        computeEncoder.setTexture(output, index: 0)
        computeEncoder.setTexture(input, index: 1)
        
        
        if let input_texture2 {
            computeEncoder.setTexture(input_texture2, index: 2)
        }
        
        if let input_texture3 {
            computeEncoder.setTexture(input_texture3, index: 3)
        }
        
        if let input_texture4 {
            computeEncoder.setTexture(input_texture4, index: 4)
        }
        
        if let buffer = buffer1 {
            computeEncoder.setBuffer(buffer, offset:0 , index: 1)
        }
        
        if let buffer = buffer2 {
            computeEncoder.setBuffer(buffer, offset:0 , index: 2)
        }
        
        computeEncoder.label = "Compute Encoder \(kernalName.capitalized)"
        computeEncoder.setComputePipelineState(computePipeline)
        computeEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadsPerThreadgroup)
        computeEncoder.endEncoding()
        //print("target text size:\(target_texture.width),\(target_texture.height)")
        return target_texture
    }
    
    public func createTarget(size:CGSize) {
        let width = Int(size.width)
        let height = Int(size.height)
        output = makeTexture(width:width, height: height,lable: "Target \(kernalName.capitalized)",renderTarget: renderTarget)!
    }
    
    public func drawableSizeWillChange(_ size:CGSize) {
        createTarget(size:size)
    }
    
}


