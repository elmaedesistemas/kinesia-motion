//
//  JointVisionTests.swift
//  KinesiaMotion
//
//  Created by Deivy Mejia Ruiz on 4/10/26.
//

import Testing
import Vision
import KinesiaMotion
@testable import KinesiaMotionVision

private typealias Joint = KinesiaMotion.Joint

@Suite("Joint + Vision")
struct JointVisionTests {
    @Test func allNineteenVisionJointsAreMapped() {
        #expect(Joint.visionNames.count == 19)
        #expect(Set(Joint.visionNames.values).count == 19)
    }

    @Test func frontCameraSwapsSides() {
        #expect(Joint(visionName: .leftWrist, mirrored: true) == .rightWrist)
        #expect(Joint(visionName: .rightKnee, mirrored: true) == .leftKnee)
    }

    @Test func backCameraKeepsSides() {
        #expect(Joint(visionName: .leftWrist, mirrored: false) == .leftWrist)
    }

    @Test func midlineNeverSwaps() {
        #expect(Joint(visionName: .neck, mirrored: true) == .neck)
        #expect(Joint(visionName: .root, mirrored: true) == .root)
        #expect(Joint(visionName: .nose, mirrored: true) == .nose)
    }

    @Test func mirroringTwiceGivesTheSameJoint() {
        for joint in Joint.allCases {
            #expect(joint.mirrored.mirrored == joint)
        }
    }
}
