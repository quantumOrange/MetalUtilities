//
//  File.swift
//  MetalUtilities
//
//  Created by David Crooks on 29/07/2025.
//

import Foundation
import simd
import Metal
import MetalKit

public final class VertexRenderer<Uniforms, Vertex:VertexDescribable> : TextureProvider, TextureMaker {
    
    public let pixelFormat:MTLPixelFormat
    public let device:MTLDevice
    let library:MTLLibrary
    var pipelineState:MTLRenderPipelineState!
    let commandQueue: MTLCommandQueue
    let name:String
    
    public func update(uniforms value:Uniforms) {
        uniforms.uniforms = value
    }
    
    var uniforms: UniformsBuffer<Uniforms>
    public var target_texture: (any MTLTexture)?
    
    var vertexBufferProvider: VertexBuffer
    
    public var input0:TextureProvider?
    public var input1:TextureProvider?
    public var input2:TextureProvider?
    public var input3:TextureProvider?
    public var input4:TextureProvider?
    
    var textureDestination0:TextureDestination = .fragmentOnly
    var textureDestination1:TextureDestination = .fragmentOnly
    var textureDestination2:TextureDestination = .fragmentOnly
    var textureDestination3:TextureDestination = .fragmentOnly
    var textureDestination4:TextureDestination = .fragmentOnly
    
    public init( commandQueue:MTLCommandQueue, library:MTLLibrary,  vertexBuffer: VertexBuffer,initialUniforms:Uniforms , vertex:String, fragment:String, size:CGSize? = nil,name:String? = nil, pixelFormat:MTLPixelFormat = .bgra8Unorm, enableBlending:Bool = false) throws {
        self.commandQueue = commandQueue
        self.device = commandQueue.device
        self.pixelFormat = pixelFormat
       
        self.library = library
        
        self.name = name ?? "\(vertex)-\(fragment)"
        self.vertexBufferProvider = vertexBuffer
        
        self.uniforms = UniformsBuffer(device:commandQueue.device, initialValue: initialUniforms)
        
        if let  size {
            createTarget(size:size)
        }
            
        try createPipelines(enableBlending: enableBlending,vertex:vertex,fragment:fragment)
    }
    
    public func render(commandBuffer: any MTLCommandBuffer,t:Float,dt:Float) -> (any MTLTexture)? {
        uniforms.updateUniforms()
        guard let vertexBuffer =  vertexBufferProvider.update(commandBuffer: commandBuffer)
        else { return nil}
        
        let input_texture0 = input0?.render(commandBuffer: commandBuffer,t:t,dt:dt)
        let input_texture1 = input1?.render(commandBuffer: commandBuffer,t:t,dt:dt)
        let input_texture2 = input2?.render(commandBuffer: commandBuffer,t:t,dt:dt)
        let input_texture3 = input3?.render(commandBuffer: commandBuffer,t:t,dt:dt)
        let input_texture4 = input4?.render(commandBuffer: commandBuffer,t:t,dt:dt)
        
        let renderPass = MTLRenderPassDescriptor()
        
        renderPass.colorAttachments[0].texture = target_texture // This is where we are going to draw
        renderPass.colorAttachments[0].clearColor = MTLClearColor(red:0.0,green:0.0,blue:0.0,alpha:1.0)
        renderPass.colorAttachments[0].loadAction =  .clear
        renderPass.colorAttachments[0].storeAction = .store
        
       
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPass)
        else { return nil }
        
        renderEncoder.setRenderPipelineState(pipelineState)
        
        // here we set the uniforms for both vertex and fragment shaders.
        renderEncoder.setVertexBuffer(uniforms.uniformBuffer, offset: uniforms.uniformBufferOffset, index: 1)
        renderEncoder.setFragmentBuffer(uniforms.uniformBuffer, offset: uniforms.uniformBufferOffset, index: 1)
        
        // Here we set the veticies
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        if let input_texture0 {
            renderEncoder.setFragmentTexture(input_texture0, index: 0)
        }
        
        if let input_texture1 {
            renderEncoder.setFragmentTexture(input_texture1, index: 1)
        }
        
        if let input_texture2 {
            renderEncoder.setFragmentTexture(input_texture2, index: 2)
        }
        
        if let input_texture3 {
            renderEncoder.setFragmentTexture(input_texture3, index: 3)
        }
        
        if let input_texture4 {
            renderEncoder.setFragmentTexture(input_texture4, index: 4)
        }
        
        // This command tells metal to interpret the vertices as points (rather than the verticies of triangles, which is typical) and draw a little square for each one
        renderEncoder.drawPrimitives(type: vertexBufferProvider.type, vertexStart:  vertexBufferProvider.start, vertexCount:vertexBufferProvider.count)
        
        renderEncoder.endEncoding()

        return target_texture
    }
    
    
    func createPipelines(enableBlending: Bool,vertex:String,fragment:String) throws {
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
       
        pipelineDescriptor.vertexFunction  = library.makeFunction(name:vertex)
        pipelineDescriptor.fragmentFunction = library.makeFunction(name:fragment)
        
        pipelineDescriptor.label = "\(name) Pipeline"
        
        // pipelineDescriptor.sampleCount = view.sampleCount
        pipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat
        // pipelineDescriptor.depthAttachmentPixelFormat = view.depthStencilPixelFormat
        // pipelineDescriptor.stencilAttachmentPixelFormat = view.depthStencilPixelFormat
        
        pipelineDescriptor.vertexDescriptor = Vertex.vertexDescriptor(bufferIndex: 0)
        
        if let attachmentDescriptor = pipelineDescriptor.colorAttachments[0] {
            // Blending: we are doing blending programatically in the shader, so we switch it off here.
            
            if enableBlending {
                attachmentDescriptor.isBlendingEnabled = true
                
                attachmentDescriptor.rgbBlendOperation = MTLBlendOperation.add
                attachmentDescriptor.sourceRGBBlendFactor = MTLBlendFactor.sourceAlpha
                attachmentDescriptor.destinationRGBBlendFactor = MTLBlendFactor.oneMinusSourceAlpha
                
                attachmentDescriptor.alphaBlendOperation = MTLBlendOperation.add
                attachmentDescriptor.sourceAlphaBlendFactor = MTLBlendFactor.sourceAlpha
                attachmentDescriptor.destinationAlphaBlendFactor = MTLBlendFactor.oneMinusSourceAlpha
            }
            else {
                attachmentDescriptor.isBlendingEnabled = false
            }
        }
        
        do {
            try pipelineState = device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            print("Failed to created anchor geometry pipeline state, error \(error)")
        }
    }

    public func createTarget(size:CGSize) {
        let width = Int(size.width)
        let height = Int(size.height)
        target_texture = makeTexture(width:width, height: height,lable: "Target \(name.capitalized)",renderTarget: true)
    }
    
    public func drawableSizeWillChange(_ size:CGSize) {
        createTarget(size:size)
    }
}
