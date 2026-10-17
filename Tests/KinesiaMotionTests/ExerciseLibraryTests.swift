//
//  ExerciseLibraryTests.swift
//  KinesiaMotion
//
//  Created by Deivy Mejia Ruiz on 4/10/26.
//

import CoreGraphics
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

    @Test func everyRegionHasAnExercise() {
        let covered = Set(ExerciseLibrary.all.map(\.region))
        for region: BodyRegion in [.neck, .shoulder, .elbow, .hip, .knee, .ankle] {
            #expect(covered.contains(region), "No exercise for \(region)")
        }
    }

    /// Standing still must read as rest with clean form, on both sides, for every exercise.
    /// Catches a measure wired backwards (e.g. reading 180 when it should read 0).
    @Test(arguments: ExerciseLibrary.all)
    func standingStillIsRest(_ exercise: ExerciseDefinition) {
        let pose = standingPose()
        for side in BodySide.allCases {
            let value = exercise.primary.value(in: pose, side: side)
            let rest: Double = switch exercise.kind {
            case let .reps(low, _): low
            case let .hold(threshold, _): threshold
            }
            #expect(value.map { $0 < rest } == true, "\(exercise.id) \(side) reads \(String(describing: value))")
            for rule in exercise.rules {
                #expect(rule.isBroken(in: pose, side: side) == false, "\(exercise.id) \(side) breaks \(rule.feedback)")
            }
        }
    }

    @Test func armRaisedForwardReadsShoulderFlexion() {
        var pose = standingPose()
        // Right arm straight out in front (side view): elbow and wrist level with the shoulder.
        pose.points[.rightElbow] = CGPoint(x: 90, y: 0)
        pose.points[.rightWrist] = CGPoint(x: 220, y: 0)
        #expect(isClose(ExerciseLibrary.shoulderFlexion.primary.value(in: pose, side: .right), 90))
        #expect(ExerciseLibrary.shoulderFlexion.rules.allSatisfy { $0.isBroken(in: pose, side: .right) == false })
    }

    @Test func shinLeaningForwardReadsDorsiflexion() {
        var pose = standingPose()
        // Lunge: the knee travels forward over a planted ankle, shin 35° from vertical.
        let ankle = pose.points[.rightAnkle]!
        let r = 35 * Double.pi / 180
        pose.points[.rightKnee] = CGPoint(x: ankle.x + 200 * sin(r), y: ankle.y - 200 * cos(r))
        #expect(isClose(ExerciseLibrary.ankleDorsiflexionLunge.primary.value(in: pose, side: .right), 35))
    }

    @Test func readsAHandWrittenHold() throws {
        let json = #"[{"id":"ankle.dorsiflexion.lunge","region":"ankle","view":"side","kind":{"hold":{"threshold":15,"seconds":3}},"primary":{"fromVertical":{"from":"knee","to":"ankle"}},"rules":[{"feedback":"keepTrunkUpright","measure":{"fromVertical":{"from":"shoulder","to":"hip"}},"allowed":[0,30]}],"defaultTarget":35}]"#
        let decoded = try ExerciseLibrary.decode(from: Data(json.utf8))
        #expect(decoded.first == ExerciseLibrary.ankleDorsiflexionLunge)
    }

    @Test func elbowRuleCatchesShoulderCheating() {
        let rule = ExerciseLibrary.elbowFlexion.rules[0]
        #expect(rule.isBroken(in: elbowPose(flexion: 100, upperArm: 5), side: .right) == false)
        #expect(rule.isBroken(in: elbowPose(flexion: 100, upperArm: 50), side: .right) == true)
    }
}
