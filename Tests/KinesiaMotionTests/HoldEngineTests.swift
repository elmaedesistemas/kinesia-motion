//
//  HoldEngineTests.swift
//  KinesiaMotion
//

import Foundation
import Testing
@testable import KinesiaMotion

/// Elbow flexion as a hold, so the existing test poses can drive it.
private let elbowHold = ExerciseDefinition(
    id: "test.elbow.hold",
    region: .elbow,
    view: .side,
    kind: .hold(threshold: 30, seconds: 2),
    primary: .flexion(a: "shoulder", vertex: "elbow", b: "wrist"),
    rules: ExerciseLibrary.elbowFlexion.rules,
    defaultTarget: 120
)

private func makeEngine() -> RepEngine {
    var engine = RepEngine(definition: elbowHold, side: .right)
    engine.smoothing = 1
    return engine
}

/// Climbs to `angle` in 10° steps, holds it for `seconds`, then drops back to 0. ~24 FPS.
private func holdPoses(angle: Double, seconds: Double, upperArm: Double = 0, startingAt start: TimeInterval = 0) -> [Pose] {
    var angles = Array(stride(from: 0.0, to: angle, by: 10))
    angles += Array(repeating: angle, count: Int(seconds * 24) + 1)
    angles += [0]
    return angles.enumerated().map { index, value in
        elbowPose(flexion: value, upperArm: upperArm, time: start + Double(index) / 24)
    }
}

@Suite("RepEngine · hold")
struct HoldEngineTests {
    @Test func steadyHoldCounts() {
        var engine = makeEngine()
        let events = holdPoses(angle: 110, seconds: 2.2).flatMap { engine.process($0) }

        #expect(engine.count == 1)
        #expect(isClose(engine.reps.first?.peak, 110))
        #expect((engine.reps.first?.duration ?? 0) >= 2)
        #expect(events.first == .holdStarted)
        #expect(events.contains { if case .repCompleted = $0 { true } else { false } })
        #expect(engine.holdProgress == nil)
    }

    @Test func letGoTooSoonIsIgnored() {
        var engine = makeEngine()
        let events = holdPoses(angle: 110, seconds: 1).flatMap { engine.process($0) }

        #expect(engine.count == 0)
        #expect(engine.rejected.isEmpty)
        #expect(!events.contains { if case .repCompleted = $0 { true } else { false } })
    }

    @Test func progressGrowsWhileHolding() {
        var engine = makeEngine()
        let poses = holdPoses(angle: 110, seconds: 2.2)
        // Climb (11 frames) plus one second at the top.
        poses.prefix(11 + 24).forEach { _ = engine.process($0) }
        let progress = engine.holdProgress ?? 0
        #expect(progress > 0.4 && progress < 0.6)
    }

    @Test func driftingRestartsTheClock() {
        var engine = makeEngine()
        // 1.5 s at 80°, then pushes on to 110° for 1.5 s: neither stretch reaches 2 s.
        let low = (0..<36).map { elbowPose(flexion: 80, time: Double($0) / 24) }
        let high = (36..<72).map { elbowPose(flexion: 110, time: Double($0) / 24) }
        (low + high).forEach { _ = engine.process($0) }
        #expect(engine.count == 0)
    }

    @Test func oneHoldPerTrip() {
        var engine = makeEngine()
        // Stays up for 5 s: still a single hold until the patient goes back to rest.
        holdPoses(angle: 110, seconds: 5).forEach { _ = engine.process($0) }
        #expect(engine.count == 1)

        holdPoses(angle: 115, seconds: 2.2, startingAt: 10).forEach { _ = engine.process($0) }
        #expect(engine.count == 2)
    }

    @Test func cheatingDuringTheHoldRejectsIt() {
        var engine = makeEngine()
        let events = holdPoses(angle: 110, seconds: 2.2, upperArm: 60).flatMap { engine.process($0) }

        #expect(engine.count == 0)
        #expect(engine.rejected.first?.faults.contains(.keepUpperArmStill) == true)
        #expect(events.contains(.formFault(.keepUpperArmStill)))
    }

    @Test func holdRoundTripsThroughJSON() throws {
        let data = try JSONEncoder().encode(elbowHold)
        let text = String(decoding: data, as: UTF8.self)
        #expect(text.contains(#""hold":{"#))
        #expect(try JSONDecoder().decode(ExerciseDefinition.self, from: data) == elbowHold)
    }
}
