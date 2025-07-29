//
//  File.swift
//  
//
//  Created by David Crooks on 17/06/2022.
//

import Foundation
import simd
import Metal
//import UIKit
import MetalKit


struct PassthroughUniforms {
    var value:Float
}

extension PassthroughUniforms {
    static var alignedUniformsSize: Int {
        (MemoryLayout<Self>.size + 0xFF) & -0x100
    }
}

public protocol ViewRendererDelegate: AnyObject  {
    func drawableSizeWillChange(_ size:CGSize)
    func update()
    func onCompleteRender(texture:MTLTexture)
}

public final class ViewRenderer:NSObject,MTKViewDelegate {
    let pixelFormat:MTLPixelFormat = .bgra8Unorm
    let inFlightSemaphore = DispatchSemaphore(value: 3)
    let maxBuffersInFlight = 3
    
    let positions:[SIMD2<Float>] = [[-1.0, -1.0],
    [1.0, -1.0],
    [-1.0,  1.0],
    [1.0,  1.0]]
    
    let texCoords:[SIMD2<Float>] = [[ 0.0, 1.0],
     [1.0, 1.0],
     [ 0.0, 0.0],
     [1.0, 0.0]]
    
    enum Errors : Error {
        case cannotCompileShaders
        case cannotMakeLib
        case cannotBuildBuffer
        case unableToCreateUniformBuffer
        case cannotMakeComandBuffer
        case failedToRenderFrame
    }
    
    public init(commandQueue:MTLCommandQueue, renderPipeline:TextureProvider, library:MTLLibrary? = nil, vertex:String? = nil, fragment:String? = nil) throws {
        let device = commandQueue.device
        self.commandQueue = commandQueue
        self.device = device
        
        if vertex != nil || fragment != nil {
            self.library =  library ?? device.makeDefaultLibrary()
        }
        else {
            let lib = try device.makeDefaultLibrary(bundle: Bundle.module)
            self.library =  library ?? lib
        }
        
        let uniformBufferSize = PassthroughUniforms.alignedUniformsSize * maxBuffersInFlight
        
        guard let buffer = device.makeBuffer(length:uniformBufferSize, options:[MTLResourceOptions.storageModeShared]) else {  throw Errors.unableToCreateUniformBuffer }
        uniformBuffer = buffer
        self.uniformBuffer.label = "UniformBuffer"
        uniforms = UnsafeMutableRawPointer(uniformBuffer.contents()).bindMemory(to:PassthroughUniforms.self, capacity:1)
      
        self.input = renderPipeline
        super.init()
        try buildBuffers(device: device)
        try createPipeline()
    }

    var device: MTLDevice!
    var library: MTLLibrary!
    var commandQueue: MTLCommandQueue

    var pipelineState:MTLRenderPipelineState!
    
    var canvasDepthState: MTLDepthStencilState?
    var imagePlaneVertexBuffer: MTLBuffer!
  
    private var uniformBuffer: MTLBuffer
    private var uniformBufferOffset = 0
    private var uniformBufferIndex = 0
    private var uniforms: UnsafeMutablePointer<PassthroughUniforms>
    
    public weak var delagate:ViewRendererDelegate?
    
    public var input:TextureProvider
    /*
    func imagePlaneVertexData(rotation:RightAngleRotation) -> [ImageVertex] {
        zip(positions,rotation.texCoords)
            .map {
                ImageVertex(position: $0.0 , texCoord:$0.1)
            }
    }
    */
    let kImagePlaneVertexData:[ImageVertex] = [
            ImageVertex(position:[-1.0, -1.0] , texCoord:[ 0.0, 1.0]),
            ImageVertex(position:[1.0, -1.0] , texCoord: [1.0, 1.0]),
            ImageVertex(position:[-1.0,  1.0] ,texCoord: [ 0.0, 0.0]),
            ImageVertex(position:[1.0,  1.0], texCoord:[ 1.0, 0.0])
    ]
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        delagate?.drawableSizeWillChange(size)
    }
    
    var pauseRenderering = false
    
    public func draw(in view: MTKView) {
        guard !pauseRenderering else { return }
        delagate?.update()
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        
        _ = inFlightSemaphore.wait(timeout: DispatchTime.distantFuture)
        
        let semaphore = inFlightSemaphore
        
        commandBuffer.addCompletedHandler { (_ commandBuffer)-> Swift.Void in
            semaphore.signal()
            
            if let tex = self.input.target_texture {
                self.delagate?.onCompleteRender(texture: tex)
            }
        }
        
        guard let texture = input.render(commandBuffer: commandBuffer) else {
            print("view input texture is nil")
            return }
        
       // print("texture \(String(describing: texture.label))")
        if let renderDesciptor = view.currentRenderPassDescriptor, let drawable = view.currentDrawable {
            
            if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor:renderDesciptor ) {
                renderView(renderEncoder: renderEncoder, texture: texture)
                renderEncoder.endEncoding()
            }
            
            commandBuffer.present(drawable)
        }
        commandBuffer.commit()
    }

    func updateUniforms() {
        updateDynamicBufferState()
        
        uniforms.pointee = PassthroughUniforms(value: 1)
    }

    private func updateDynamicBufferState() {
        /// Update the state of our uniform buffers before rendering
        
        uniformBufferIndex = (uniformBufferIndex + 1) % maxBuffersInFlight
        uniformBufferOffset = PassthroughUniforms.alignedUniformsSize * uniformBufferIndex
        
        uniforms = UnsafeMutableRawPointer(uniformBuffer.contents() + uniformBufferOffset).bindMemory(to:PassthroughUniforms.self, capacity:1)
    }
    
    func renderView(renderEncoder: MTLRenderCommandEncoder, texture:MTLTexture) {
       
        updateUniforms()
        
        // Push a debug group allowing us to identify render commands in the GPU Frame Capture tool
        renderEncoder.pushDebugGroup("Passthrough")
        
        // Set render command encoder state
        renderEncoder.setCullMode(.none)
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setDepthStencilState(canvasDepthState)
        
        // Set mesh's vertex buffers
        renderEncoder.setVertexBuffer(imagePlaneVertexBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentBuffer(uniformBuffer, offset: uniformBufferOffset, index: 0)
        renderEncoder.setFragmentTexture(texture, index: 0)
        
        // Draw each submesh of our mesh
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.popDebugGroup()
    }
    
    private func buildBuffers(device: MTLDevice) throws {
        let imagePlaneVertexDataCount = kImagePlaneVertexData.count * MemoryLayout<ImageVertex>.stride
        imagePlaneVertexBuffer = device.makeBuffer(bytes: kImagePlaneVertexData, length: imagePlaneVertexDataCount, options: [])
        imagePlaneVertexBuffer.label = "ImagePlaneVertexBuffer"
        
    }
   
    func createPipeline(vertexShader:String = "passthroughVertex", fragmentShader:String = "passthroughFragment") throws {
        guard let vertexFunction:MTLFunction = library.makeFunction(name: vertexShader),
              let fragmentFunction:MTLFunction = library.makeFunction(name: fragmentShader) else {throw Errors.cannotCompileShaders}
       
        // Create a pipeline state for rendering the captured image
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.label = "PassthouPipeline"
        //pipelineStateDescriptor.sampleCount = 1
        pipelineStateDescriptor.vertexFunction = vertexFunction
        pipelineStateDescriptor.fragmentFunction = fragmentFunction
        pipelineStateDescriptor.vertexDescriptor = ImageVertex.vertexDescriptor()
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = pixelFormat
       
        do {
            try pipelineState = device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        } catch let error {
            print("Failed to created captured image pipeline state, error \(error)")
        }
        
        let canvasDepthStateDescriptor = MTLDepthStencilDescriptor()
        canvasDepthStateDescriptor.depthCompareFunction = .always
        canvasDepthStateDescriptor.isDepthWriteEnabled = false
        canvasDepthState = device.makeDepthStencilState(descriptor: canvasDepthStateDescriptor)
    }
}
