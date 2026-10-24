//
//  Pose+Vision.swift
//  KinesiaMotion
//
//  Created by Deivy Mejia Ruiz on 24/10/26.
//

import CoreGraphics
import Vision
import KinesiaMotion

extension Pose {
    /// One Vision result as a `Pose`: pixels in the upright image, y down, sides as the patient's.
    /// No observation gives an empty pose, which tells the session the person left the frame.
    init(observation: VNHumanBodyPoseObservation?,
         imageSize: CGSize,
         timestamp: TimeInterval,
         mirrored: Bool,
         minimumConfidence: Float) {
        var points: [Joint: CGPoint] = [:]
        var confidence: [Joint: Double] = [:]
        if let observation, let recognized = try? observation.recognizedPoints(.all) {
            for (name, point) in recognized where point.confidence > minimumConfidence {
                guard let joint = Joint(visionName: name, mirrored: mirrored) else { continue }
                // Vision: normalized, origin bottom-left. Pose: pixels, y grows downward.
                points[joint] = CGPoint(
                    x: point.location.x * imageSize.width,
                    y: (1 - point.location.y) * imageSize.height
                )
                confidence[joint] = Double(point.confidence)
            }
        }
        self.init(points: points, timestamp: timestamp, imageSize: imageSize, confidence: confidence)
    }
}
