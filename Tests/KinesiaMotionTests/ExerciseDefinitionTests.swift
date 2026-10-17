//
//  ExerciseDefinitionTests.swift
//  KinesiaMotion
//
//  Created by Deivy Mejia Ruiz on 4/10/26.
//

import Foundation
import Testing
@testable import KinesiaMotion

@Suite("FormRule")
struct FormRuleTests {
    private let upperArmStill = FormRule(
        feedback: .keepUpperArmStill,
        measure: .fromVertical(from: "shoulder", to: "elbow"),
        allowed: 0...30
    )

    @Test func armByTheSideIsFine() {
        #expect(upperArmStill.isBroken(in: elbowPose(flexion: 90, upperArm: 10), side: .right) == false)
    }

    @Test func swingingTheArmBreaksTheRule() {
        #expect(upperArmStill.isBroken(in: elbowPose(flexion: 90, upperArm: 60), side: .right) == true)
    }

    @Test func invisibleJointsAreNotJudged() {
        #expect(upperArmStill.isBroken(in: elbowPose(flexion: 90), side: .left) == nil)
    }
}

@Suite("ExerciseDefinition")
struct ExerciseDefinitionTests {
    private let sample = ExerciseDefinition(
        id: "test.elbow",
        region: .elbow,
        view: .side,
        kind: .reps(low: 30, high: 90),
        primary: .flexion(a: "shoulder", vertex: "elbow", b: "wrist"),
        rules: [
            FormRule(feedback: .keepUpperArmStill,
                     measure: .fromVertical(from: "shoulder", to: "elbow"),
                     allowed: 0...30)
        ],
        defaultTarget: 120
    )

    @Test func roundTripsThroughJSON() throws {
        let data = try JSONEncoder().encode(sample)
        let decoded = try JSONDecoder().decode(ExerciseDefinition.self, from: data)
        #expect(decoded == sample)
    }

    @Test func jsonIsReadable() throws {
        let text = String(decoding: try JSONEncoder().encode(sample), as: UTF8.self)
        #expect(text.contains(#""reps":{"#))
        #expect(text.contains(#""allowed":[0,30]"#))
        #expect(text.contains(#""feedback":"keepUpperArmStill""#))
    }
}
