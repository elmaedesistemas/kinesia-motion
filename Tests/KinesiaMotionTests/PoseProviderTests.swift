//
//  PoseProviderTests.swift
//  KinesiaMotion
//
//  Created by Deivy Mejia Ruiz on 4/10/26.
//


import Foundation
import Testing
@testable import KinesiaMotion

@Suite("RecordedPoseProvider")
struct PoseProviderTests {
    @Test func deliversEveryPoseInOrder() async {
        let recording = (0..<5).map { elbowPose(flexion: Double($0 * 10), time: Double($0)) }
        var received: [TimeInterval] = []

        for await pose in RecordedPoseProvider(recording).poses() {
            received.append(pose.timestamp)
        }

        #expect(received == [0, 1, 2, 3, 4])
    }

    @Test func stopsWhenTheConsumerStops() async {
        let recording = oneRep(peak: 130)
        var count = 0

        for await _ in RecordedPoseProvider(recording).poses() {
            count += 1
            if count == 2 { break }
        }

        #expect(count == 2)
    }

    @Test func feedsTheEngineEndToEnd() async {
        var engine = RepEngine(definition: ExerciseLibrary.elbowFlexion, side: .right)
        engine.smoothing = 1
        let provider = RecordedPoseProvider(oneRep(peak: 120) + oneRep(peak: 130, startingAt: 2))

        for await pose in provider.poses() {
            _ = engine.process(pose)
        }

        #expect(engine.count == 2)
    }
}
