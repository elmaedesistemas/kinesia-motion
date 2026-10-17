//
//  Pose.swift
//  KinesiaMotion
//
//  Created by Deivy Mejia Ruiz on 4/10/26.
//

import CoreGraphics
import Foundation

/// One frame of body landmarks.
///
/// Contract (the adapter that builds poses must respect it):
/// - Coordinates are in image pixels, with y growing **downward**.
/// - Sides are **anatomical**: the patient's real left and right, already un-mirrored.
/// - Only confident points are included (low-confidence joints are left out).
public struct Pose: Sendable {
    public var points: [Joint: CGPoint]
    public var timestamp: TimeInterval
    /// Size of the image the points were measured in. Lets a UI draw them over the camera.
    public var imageSize: CGSize?

    public init(points: [Joint: CGPoint], timestamp: TimeInterval, imageSize: CGSize? = nil) {
        self.points = points
        self.timestamp = timestamp
        self.imageSize = imageSize
    }

    public subscript(joint: Joint) -> CGPoint? {
        points[joint]
    }
}
