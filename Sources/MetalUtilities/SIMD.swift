//
//  File.swift
//  MetalUtilities
//
//  Created by David Crooks on 29/07/2025.
//

import Foundation
import simd

public extension SIMD4<Float> {
    public var xyz:SIMD3<Float> {
        [x,y,z]
    }
    
    var xy:SIMD2<Float> {
        [x,y]
    }
}

public extension SIMD3<Float> {
    var xy:SIMD2<Float> {
        [x,y]
    }
}


public extension SIMD2<Float> {
    func lift3dPoint() -> SIMD4<Float> {
        [x,y,1]
    }
    
    func lift4dPoint(z:Float = 0) -> SIMD4<Float> {
        [x,y,z,1]
    }
    
    func lift4dVector(z:Float = 0)->SIMD4<Float> {
        [x,y,z,0]
    }
    
    func normaizeledViewCoords(size:SIMD2<Float>) -> SIMD2<Float> {
        var p = SIMD2<Float>(-1,-1) + 2.0 * self/size
        p.y = -p.y
        return p
    }
}
