//
//  ExerciseLibraryTests.swift
//  KinesiaMotion
//
//  Created by Deivy Mejia Ruiz on 4/10/26.
//

import Foundation
import Testing
@testable import KinesiaMotion

@Suite("ExerciseLibrary")
struct ExerciseLibraryTests {
    @Test func idsAreUnique() {
        let ids = ExerciseLibrary.all.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func findsByIdAndRegion() {
        #expect(ExerciseLibrary.definition(id: "elbow.flexion") == ExerciseLibrary.elbowFlexion)
        #expect(ExerciseLibrary.definition(id: "nope") == nil)
        #expect(ExerciseLibrary.definitions(for: .knee).map(\.id) == ["knee.flexion.standing"])
    }

    @Test func libraryRoundTripsThroughJSON() throws {
        let data = try ExerciseLibrary.encode(ExerciseLibrary.all)
        let decoded = try ExerciseLibrary.decode(from: data)
        #expect(decoded == ExerciseLibrary.all)
    }

    @Test func readsAHandWrittenExercise() throws {
        let json = """
        [{
          "id": "elbow.flexion", "region": "elbow", "view": "side",
          "kind": { "reps": { "low": 30, "high": 90 } },
          "primary": { "flexion": { "a": "shoulder", "vertex": "elbow", "b": "wrist" } },
          "rules": [{
            "feedback": "keepUpperArmStill",
            "measure": { "fromVertical": { "from": "shoulder", "to": "elbow" } },
            "allowed": [0, 30]
          }],
          "defaultTarget": 120
        }]
        """
        let decoded = try ExerciseLibrary.decode(from: Data(json.utf8))
        #expect(decoded.first == ExerciseLibrary.elbowFlexion)
    }

    @Test func unknownLandmarkIsRejected() {
        let json = #"[{"id":"x","region":"elbow","view":"side","kind":{"reps":{"low":1,"high":2}},"primary":{"tilt":{"a":"elbo","b":"wrist"}},"rules":[],"defaultTarget":1}]"#
        #expect(throws: DecodingError.self) {
            try ExerciseLibrary.decode(from: Data(json.utf8))
        }
    }

    @Test func elbowRuleCatchesShoulderCheating() {
        let rule = ExerciseLibrary.elbowFlexion.rules[0]
        #expect(rule.isBroken(in: elbowPose(flexion: 100, upperArm: 5), side: .right) == false)
        #expect(rule.isBroken(in: elbowPose(flexion: 100, upperArm: 50), side: .right) == true)
    }
}
