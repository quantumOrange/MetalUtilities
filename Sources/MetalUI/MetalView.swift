//
//  SwiftUIView.swift
//  MetalUtilities
//
//  Created by David Crooks on 29/07/2025.
//

import SwiftUI

import SwiftUI
import Metal
import MetalKit

#if os(iOS) || os(watchOS) || os(tvOS)
    import UIKit
#elseif os(macOS)
   import AppKit
#endif


protocol MetalViewDelegate : MTKViewDelegate {
    func initialise(view:MTKView)
}


#if os(iOS) || os(watchOS) || os(tvOS)

public struct MetalView: UIViewRepresentable  {
   
    public init(delegate:MTKViewDelegate,pixelFormat:MTLPixelFormat = .bgra8Unorm,framebufferOnly:Bool = true){
        self.delegate = delegate
        self.pixelFormat = pixelFormat
        self.framebufferOnly = framebufferOnly
    }
    
    let delegate:MTKViewDelegate
    let pixelFormat:MTLPixelFormat
    let framebufferOnly:Bool
    
    public func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView(frame: .zero)
        
        mtkView.backgroundColor = UIColor.clear
        mtkView.delegate =  delegate
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.colorPixelFormat = pixelFormat
        mtkView.framebufferOnly = framebufferOnly
        
        return mtkView
    }
    
    public class Coordinator {
       
    }
    
    public func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
    public func updateUIView(_ uiView: MTKView, context: Context) {
        
    }
}

#elseif os(macOS)
struct MetalView: NSViewRepresentable  {
    typealias NSViewType =  MTKView

    public init(delegate:MetalViewDelegate, device:MTLDevice){
        self.delegate = delegate
        self.device = device
    }
    
    let delegate:MetalViewDelegate
    let device:MTLDevice
    
    public func makeNSView(context: Context) -> MTKView {
        let mtkView = MTKView(frame: .zero, device: device)

       // mtkView.backgroundColor = UIColor.clear
        

        delegate.initialise(view: mtkView)
        mtkView.delegate =  delegate
        mtkView.framebufferOnly = false
        return mtkView
    }
    
    public class Coordinator {
       
    }
    
    public func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
    public func updateNSView(_ uiView: MTKView, context: Context) {
        
    }
}
#endif
