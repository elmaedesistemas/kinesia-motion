//
//  RepEngineTests.swift
//  KinesiaMotion
//
//  Created by Deivy Mejia Ruiz on 4/10/26.
//

import Foundation
import Testing
@testable import KinesiaMotion

private func makeEngine() -> RepEngine {
    var engine = RepEngine(definition: ExerciseLibrary.elbowFlexion, side: .right)
    engine.smoothing = 1 // deterministic tests
    return engine
}

@Suite("RepEngine")
struct RepEngineTests {
    @Test func cleanRepCounts() {
        var engine = makeEngine()
        let events = oneRep(peak: 130).flatMap { engine.process($0) }

        #expect(engine.count == 1)
        #expect(isClose(engine.reps.first?.peak, 130))
        #expect(events.contains { if case .repCompleted = $0 { true } else { false } })
    }

    @Test func swingingTheShoulderDoesNotCount() {
        var engine = makeEngine()
        let events = oneRep(peak: 130, upperArm: 60).flatMap { engine.process($0) }

        #expect(engine.count == 0)
        #expect(engine.rejected.first?.faults.contains(.keepUpperArmStill) == true)
        #expect(events.contains(.formFault(.keepUpperArmStill)))
    }

    @Test func liveCueFiresOncePerRep() {
        var engine = makeEngine()
        let events = oneRep(peak: 130, upperArm: 60).flatMap { engine.process($0) }
        #expect(events.filter { $0 == .formFault(.keepUpperArmStill) }.count == 1)
    }

    @Test func partialMovementIsIgnored() {
        var engine = makeEngine()
        let events = oneRep(peak: 70).flatMap { engine.process($0) }

        #expect(engine.count == 0)
        #expect(engine.rejected.isEmpty)
        #expect(events.isEmpty)
    }

    @Test func threeRepsInARow() {
        var engine = makeEngine()
        let poses = oneRep(peak: 120) + oneRep(peak: 125, startingAt: 2) + oneRep(peak: 130, startingAt: 4)
        poses.forEach { _ = engine.process($0) }

        #expect(engine.count == 3)
        #expect(engine.peaks.map { Int($0.rounded()) } == [120, 125, 130])
    }

    @Test func missingJointsAreNotPunished() {
        var engine = makeEngine()
        let pose = Pose(points: [.rightShoulder: .zero], timestamp: 0)
        #expect(engine.process(pose).isEmpty)
        #expect(engine.value == nil)
    }

    @Test func resetStartsOver() {
        var engine = makeEngine()
        oneRep(peak: 130).forEach { _ = engine.process($0) }
        engine.reset()
        #expect(engine.count == 0)
        #expect(engine.best == 0)
        #expect(engine.value == nil)
    }
}
