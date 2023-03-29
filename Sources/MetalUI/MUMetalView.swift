//
//  SwiftUIView.swift
//  
//
//  Created by David Crooks on 22/03/2023.
//


import SwiftUI
import Metal
import MetalKit
import UIKit

@MainActor
public protocol MetalViewDelegating {
    func configure(view:  MTKView)
    func draw(view: MTKView)
    func sizeWillChange(size:CGSize,view:MTKView)
}


public struct MUMetalView: UIViewRepresentable  {
    
    public init(delegate:MetalViewDelegating, device:MTLDevice){
        //print("INIT VIEW")
        self.actions = delegate
        self.device = device
    }
    
    let actions:MetalViewDelegating
    let device:MTLDevice
    
    public func makeUIView(context: Context) -> MTKView {
        assert(Thread.isMainThread)
        let mtkView = MTKView(frame: .zero, device: device)
        mtkView.backgroundColor = UIColor.black
        mtkView.delegate = context.coordinator
        //print("configure \(actions)")
        actions.configure(view:mtkView)
        return mtkView
    }
    
    
    public class Coordinator: NSObject, MTKViewDelegate {
        let actions:MetalViewDelegating
        
        init(actions:MetalViewDelegating) {
            assert(Thread.isMainThread)
            
            self.actions = actions
        }
        
        @MainActor public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            assert(Thread.isMainThread)
          //  print("sizeWillChange \(actions)")
            
            actions.sizeWillChange(size: size, view: view)
        }
        
        @MainActor public func draw(in view: MTKView) {
            assert(Thread.isMainThread)
           // print("draw \(actions)")
            
            actions.draw(view: view)
        }
        
    }
    
    public func makeCoordinator() -> Coordinator {
        return Coordinator(actions: actions)
    }
    
    public func updateUIView(_ uiView: MTKView, context: Context) {
        
    }
}

