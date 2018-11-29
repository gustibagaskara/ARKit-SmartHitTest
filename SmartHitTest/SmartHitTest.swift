//
//  SmartHitTest.swift
//  SmartHitTest
//
//  Created by Max Cobb on 11/28/18.
//  Copyright © 2018 Apple Inc. All rights reserved.
//

import ARKit

public extension ARSCNView {
	/// hitTest uses a series of methods to estimate the position of the anchor, like looking
	/// for the best position based on what we know about other detected planes in the scene
	///
	/// - Parameters:
	///   - point: A point in the 2D coordinate system of the view.
	///   - infinitePlane: set this to true if you're moving an object around on a plane
	///   - objectPosition: Used for dragging objects in AR, will add Apple's bits for this later
	///   - allowedAlignments: What plane alignments you want to use for the hit test
	/// - Returns: ARHitTestResult, check the
	public func smartHitTest(
		_ point: CGPoint? = nil, infinitePlane: Bool = false, objectPosition: float3? = nil,
		allowedAlignments: [ARPlaneAnchor.Alignment] = [.horizontal, .vertical]
	) -> ARHitTestResult? {

		let point = point ?? CGPoint(x: self.bounds.midX, y: self.bounds.midY)

		// Perform the hit test.
		let results = hitTest(point, types: [.existingPlaneUsingGeometry, .estimatedVerticalPlane, .estimatedHorizontalPlane])

		// 1. Check for a result on an existing plane using geometry.
		if let existingPlaneUsingGeometryResult = results.first(where: { $0.type == .existingPlaneUsingGeometry }),
			let planeAnchor = existingPlaneUsingGeometryResult.anchor as? ARPlaneAnchor, allowedAlignments.contains(planeAnchor.alignment) {
			return existingPlaneUsingGeometryResult
		}

		if infinitePlane {

			// 2. Check for a result on an existing plane, assuming its dimensions are infinite.
			//    Loop through all hits against infinite existing planes and either return the
			//    nearest one (vertical planes) or return the nearest one which is within 5 cm
			//    of the object's position.
			let infinitePlaneResults = hitTest(point, types: .existingPlane)

			for infinitePlaneResult in infinitePlaneResults {
				if let planeAnchor = infinitePlaneResult.anchor as? ARPlaneAnchor, allowedAlignments.contains(planeAnchor.alignment) {
					if planeAnchor.alignment == .vertical {
						// Return the first vertical plane hit test result.
						return infinitePlaneResult
					} else {
						// For horizontal planes we only want to return a hit test result
						// if it is close to the current object's position.
						if let objectY = objectPosition?.y {
							let planeY = infinitePlaneResult.worldTransform.translation.y
							if objectY > planeY - 0.05 && objectY < planeY + 0.05 {
								return infinitePlaneResult
							}
						} else {
							return infinitePlaneResult
						}
					}
				}
			}
		}

		// 3. As a final fallback, check for a result on estimated planes.
		let vResult = results.first(where: { $0.type == .estimatedVerticalPlane })
		let hResult = results.first(where: { $0.type == .estimatedHorizontalPlane })
		switch (allowedAlignments.contains(.horizontal), allowedAlignments.contains(.vertical)) {
		case (true, false):
			return hResult
		case (false, true):
			// Allow fallback to horizontal because we assume that objects meant for vertical placement
			// (like a picture) can always be placed on a horizontal surface, too.
			return vResult ?? hResult
		case (true, true):
			if hResult != nil && vResult != nil {
				return hResult!.distance < vResult!.distance ? hResult! : vResult!
			} else {
				return hResult ?? vResult
			}
		default:
			return nil
		}
	}
}