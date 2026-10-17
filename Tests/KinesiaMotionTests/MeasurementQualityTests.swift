//
//  MeasurementQualityTests.swift
//  KinesiaMotion
//

import CoreGraphics
import Foundation
import Testing
@testable import KinesiaMotion

/// `standingPose` moved into positive image coordinates.
private func placedPose(shoulderHalfWidth: CGFloat? = nil, imageSize: CGSize? = CGSize(width: 480, height: 900)) -> Pose {
    var pose = standingPose()
    if let w = shoulderHalfWidth {
        pose.points[.leftShoulder] = CGPoint(x: w, y: 0)
        pose.points[.rightShoulder] = CGPoint(x: -w, y: 0)
    }
    pose.points = pose.points.mapValues { CGPoint(x: $0.x + 300, y: $0.y + 100) }
    pose.imageSize = imageSize
    return pose
}

@Suite("SetupCheck")
struct SetupCheckTests {
    private let check = SetupCheck()

    @Test func goodPlacementHasNoIssues() {
        #expect(check.issues(in: placedPose(), exercise: ExerciseLibrary.elbowFlexion, side: .right).isEmpty)
    }

    @Test func facingTheCameraOnASideExercise() {
        let pose = placedPose(shoulderHalfWidth: 110)
        #expect(check.issues(in: pose, exercise: ExerciseLibrary.elbowFlexion, side: .right) == [.turnSideways])
        #expect(check.issues(in: pose, exercise: ExerciseLibrary.shoulderAbduction, side: .right).isEmpty)
    }

    @Test func sidewaysOnAFrontExercise() {
        let pose = placedPose(shoulderHalfWidth: 10)
        #expect(check.issues(in: pose, exercise: ExerciseLibrary.shoulderAbduction, side: .right).contains(.faceCamera))
        #expect(!check.issues(in: pose, exercise: ExerciseLibrary.elbowFlexion, side: .right).contains(.turnSideways))
    }

    @Test func farShoulderHiddenIsNotJudged() {
        var pose = placedPose(shoulderHalfWidth: 110)
        pose.points[.leftShoulder] = nil
        #expect(check.issues(in: pose, exercise: ExerciseLibrary.elbowFlexion, side: .right).isEmpty)
    }

    @Test func tooFarAway() {
        let pose = placedPose(imageSize: CGSize(width: 4000, height: 4000))
        #expect(check.issues(in: pose, exercise: ExerciseLibrary.elbowFlexion, side: .right).contains(.moveCloser))
    }

    @Test func jointAtTheEdge() {
        // The right wrist sits at y = 380, inside the bottom margin of a 385 px tall image.
        let pose = placedPose(imageSize: CGSize(width: 480, height: 385))
        #expect(check.issues(in: pose, exercise: ExerciseLibrary.elbowFlexion, side: .right).contains(.stepBack))
    }

    @Test func noImageSizeSkipsDistance() {
        let pose = placedPose(imageSize: nil)
        #expect(check.issues(in: pose, exercise: ExerciseLibrary.elbowFlexion, side: .right).isEmpty)
    }

    @Test func exerciseJointsIncludeTheRules() {
        let joints = ExerciseLibrary.kneeFlexionStanding.joints(for: .left)
        #expect(joints == [.leftHip, .leftKnee, .leftAnkle, .leftShoulder])
    }
}

@Suite("Rep metrics")
struct RepMetricsTests {
    private func makeEngine() -> RepEngine {
        var engine = RepEngine(definition: ExerciseLibrary.elbowFlexion, side: .right)
        engine.smoothing = 1
        return engine
    }

    @Test func timingAndVelocity() throws {
        var engine = makeEngine()
        oneRep(peak: 130).forEach { _ = engine.process($0) }
        let rep = try #require(engine.reps.first)

        // Leaves rest at 40° (frame 4), peaks at frame 13, back to rest at frame 23
        // (the 30° frame reads a hair under 30 in floating point).
        #expect(abs(rep.riseDuration - 9.0 / 24) < 0.001)
        #expect(abs(rep.duration - 19.0 / 24) < 0.001)
        #expect(abs(rep.returnDuration - 10.0 / 24) < 0.001)
        // 10° per frame at 24 FPS.
        #expect(abs(rep.peakVelocity - 240) < 0.5)
        #expect(rep.confidence == nil)
    }

    @Test func confidenceIsTheWeakestMeasuredJoint() throws {
        var engine = makeEngine()
        let poses = oneRep(peak: 130).map { pose -> Pose in
            var pose = pose
            pose.confidence = [.rightShoulder: 0.9, .rightElbow: 0.6, .rightWrist: 0.8, .rightHip: 0.1]
            return pose
        }
        poses.forEach { _ = engine.process($0) }

        #expect(isClose(engine.confidence, 0.6))
        #expect(isClose(try #require(engine.reps.first).confidence, 0.6))
    }

    @Test func peakSpreadMeasuresConsistency() {
        var engine = makeEngine()
        (oneRep(peak: 120) + oneRep(peak: 125, startingAt: 2) + oneRep(peak: 130, startingAt: 4))
            .forEach { _ = engine.process($0) }

        #expect(isClose(engine.reps.peakSpread, 5))
        #expect(Array(engine.reps.prefix(1)).peakSpread == nil)
    }
}

@MainActor
@Suite("MotionSession · setup")
struct MotionSessionSetupTests {
    @Test func setupIssuesAreDebounced() {
        let session = MotionSession(exercise: ExerciseLibrary.elbowFlexion, side: .right, smoothing: 1)
        let facing = placedPose(shoulderHalfWidth: 110)

        let early = (0..<11).flatMap { _ in session.process(facing) }
        #expect(!early.contains(.setupChanged([.turnSideways])))
        #expect(session.snapshot.setupIssues.isEmpty)

        #expect(session.process(facing).contains(.setupChanged([.turnSideways])))
        #expect(session.snapshot.setupIssues == [.turnSideways])

        // Turning sideways clears it after the same delay.
        let cleared = (0..<12).flatMap { _ in session.process(placedPose()) }
        #expect(cleared.contains(.setupChanged([])))
        #expect(session.snapshot.setupIssues.isEmpty)
    }

    @Test func snapshotCarriesConfidence() {
        let session = MotionSession(exercise: ExerciseLibrary.elbowFlexion, side: .right, smoothing: 1)
        var pose = elbowPose(flexion: 50)
        pose.confidence = [.rightShoulder: 0.7, .rightElbow: 0.9, .rightWrist: 0.4]
        session.process(pose)
        #expect(isClose(session.snapshot.confidence, 0.4))
    }
}
