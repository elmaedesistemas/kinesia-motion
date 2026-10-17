//
//  MeasureTests.swift
//  KinesiaMotion
//
//  Created by Deivy Mejia Ruiz on 4/10/26.
//

import Foundation
import Testing
@testable import KinesiaMotion

@Suite("Measure")
struct MeasureTests {
    private let elbowFlexion = Measure.flexion(a: "shoulder", vertex: "elbow", b: "wrist")
    private let upperArm = Measure.fromVertical(from: "shoulder", to: "elbow")

    @Test func flexionMatchesTheBuiltAngle() {
        for angle in [0.0, 45, 90, 130] {
            #expect(isClose(elbowFlexion.value(in: elbowPose(flexion: angle), side: .right), angle))
        }
    }

    @Test func fromVerticalReadsArmPosition() {
        #expect(isClose(upperArm.value(in: elbowPose(flexion: 0, upperArm: 0), side: .right), 0))
        #expect(isClose(upperArm.value(in: elbowPose(flexion: 0, upperArm: 90), side: .right), 90))
    }

    @Test func wrongSideHasNoValue() {
        // The pose only has a right arm: asking for the left must say "I don't know".
        #expect(elbowFlexion.value(in: elbowPose(flexion: 90), side: .left) == nil)
    }

    @Test func listsTheJointsItNeeds() {
        #expect(elbowFlexion.joints(for: .right) == [.rightShoulder, .rightElbow, .rightWrist])
        #expect(Measure.tilt(a: "shoulder", b: "opposite.shoulder").joints(for: .left) == [.leftShoulder, .rightShoulder])
    }

    @Test func encodesWithReadableLabels() throws {
        let data = try JSONEncoder().encode(elbowFlexion)
        let decoded = try JSONDecoder().decode(Measure.self, from: data)
        let text = String(decoding: data, as: UTF8.self)

        #expect(decoded == elbowFlexion)
        #expect(text.contains(#""vertex":"elbow""#))
    }
}
