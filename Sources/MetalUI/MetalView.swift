//
//  MetalView.swift
//  
//
//  Created by David Crooks on 11/02/2022.
//

import SwiftUI
import Metal
import MetalKit
import UIKit
import Combine

public enum Action {
    case configure(MTKView)
    case draw(MTKView)
    case sizeWillChange(CGSize,MTKView)
}

public struct MetalView<S>: UIViewRepresentable where S:Subject, S.Output == Action, S.Failure == Never {
    
    public init(actions:S, device:MTLDevice){
        self.actions = actions
        self.device = device
    }
    
    let actions:S
    let device:MTLDevice
    
    public func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView(frame: .zero, device: device)
        mtkView.backgroundColor = UIColor.black
        mtkView.delegate = context.coordinator
        actions.send(.configure(mtkView))
        return mtkView
    }
    
    public class Coordinator: NSObject, MTKViewDelegate {
        let actions:S
        
        init(actions:S) {
            self.actions = actions
        }
        
        public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            actions.send(.sizeWillChange(size, view))
        }
        
        public func draw(in view: MTKView) {
            actions.send(.draw(view))
        }
        
    }
    
    public func makeCoordinator() -> Coordinator {
        return Coordinator(actions: actions)
    }
    
    public func updateUIView(_ uiView: MTKView, context: Context) {
        
    }
}

