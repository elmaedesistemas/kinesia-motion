//
//  TestPoses.swift
//  KinesiaMotion
//
//  Created by Deivy Mejia Ruiz on 4/10/26.
//

import CoreGraphics
import Foundation
@testable import KinesiaMotion

/// Builds a right-arm pose with an exact elbow flexion.
/// `upperArm` = how far the upper arm swings away from hanging straight down.
func elbowPose(flexion: Double, upperArm: Double = 0, time: TimeInterval = 0) -> Pose {
    let r = Double.pi / 180
    let shoulder = CGPoint(x: 0, y: 0)
    let elbow = CGPoint(x: 100 * sin(upperArm * r), y: 100 * cos(upperArm * r))
    let wrist = CGPoint(
        x: elbow.x + 100 * sin((upperArm + flexion) * r),
        y: elbow.y + 100 * cos((upperArm + flexion) * r)
    )
    return Pose(points: [.rightShoulder: shoulder, .rightElbow: elbow, .rightWrist: wrist], timestamp: time)
}

func isClose(_ value: Double?, _ expected: Double) -> Bool {
    guard let value else { return false }
    return abs(value - expected) < 0.001
}


/// 0 → peak → 0 in 10° steps, at ~24 FPS. The exact peak is always included.
func oneRep(peak: Double, upperArm: Double = 0, startingAt start: TimeInterval = 0) -> [Pose] {
    var up = Array(stride(from: 0.0, to: peak, by: 10))
    up.append(peak)
    let angles = up + up.reversed().dropFirst()
    return angles.enumerated().map { index, angle in
        elbowPose(flexion: angle, upperArm: upperArm, time: start + Double(index) / 24)
    }
}
