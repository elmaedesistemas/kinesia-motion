//
//  MotionSessionTests.swift
//  KinesiaMotion
//
//  Created by Deivy Mejia Ruiz on 4/10/26.
//

import Foundation
import Testing
@testable import KinesiaMotion

@MainActor
@Suite("MotionSession")
struct MotionSessionTests {
    private func makeSession() -> MotionSession {
        MotionSession(exercise: ExerciseLibrary.elbowFlexion, side: .right, smoothing: 1)
    }

    @Test func runsAProviderToTheEnd() async {
        let session = makeSession()
        await session.run(with: RecordedPoseProvider(oneRep(peak: 120) + oneRep(peak: 130, startingAt: 2)))

        #expect(session.snapshot.repCount == 2)
        #expect(isClose(session.snapshot.best, 130))
        #expect(session.snapshot.isVisible)
        #expect(session.snapshot.isRunning == false)
    }

    @Test func listenersReceiveEventsInOrder() async {
        let session = makeSession()
        var iterator = session.events().makeAsyncIterator()

        await session.run(with: RecordedPoseProvider(oneRep(peak: 120)))

        #expect(await iterator.next() == .visibilityChanged(Visibility(isVisible: true, missingJoints: [])))
        let second = await iterator.next()
        #expect({ if case .repCompleted = second { true } else { false } }())
    }

    @Test func reportsWhatIsMissing() {
        let session = makeSession()
        for frame in 0..<10 {
            session.process(elbowPose(flexion: 40, time: Double(frame) / 24))
        }
        #expect(session.snapshot.isVisible)

        for frame in 10..<20 {
            var pose = elbowPose(flexion: 40, time: Double(frame) / 24)
            pose.points[.rightWrist] = nil
            session.process(pose)
        }
        #expect(session.snapshot.isVisible == false)
        #expect(session.snapshot.missingJoints == [.rightWrist])
    }

    @Test func resetClearsTheCount() async {
        let session = makeSession()
        await session.run(with: RecordedPoseProvider(oneRep(peak: 130)))
        session.reset()

        #expect(session.snapshot.repCount == 0)
        #expect(session.snapshot.best == 0)
    }

    @Test func configureSwitchesExercise() {
        let session = makeSession()
        session.configure(exercise: ExerciseLibrary.kneeFlexionStanding, side: .left)

        #expect(session.exercise.id == "knee.flexion.standing")
        #expect(session.snapshot.missingJoints == [.leftHip, .leftKnee, .leftAnkle])
    }
}


@MainActor
@Suite("MotionSession · first measurement")
struct BaselineTests {
    private func makeSession() -> MotionSession {
        MotionSession(exercise: ExerciseLibrary.elbowFlexion, side: .right, smoothing: 1)
    }

    @Test func finishesAfterThreeCleanReps() {
        let session = makeSession()
        session.startBaseline()

        let poses = oneRep(peak: 110) + oneRep(peak: 130, startingAt: 2) + oneRep(peak: 120, startingAt: 4)
        let events = poses.flatMap { session.process($0) }

        #expect(session.snapshot.baseline?.repsDone == 3)
        #expect(isClose(session.snapshot.baseline?.result, 120))
        #expect(events.contains(.baselineCompleted(120)))
    }

    @Test func rejectedRepsDoNotCount() {
        let session = makeSession()
        session.startBaseline()

        let cheating = oneRep(peak: 150, upperArm: 60)
        let clean = oneRep(peak: 100, startingAt: 2) + oneRep(peak: 110, startingAt: 4) + oneRep(peak: 120, startingAt: 6)
        (cheating + clean).forEach { session.process($0) }

        #expect(session.snapshot.rejectedCount == 1)
        #expect(isClose(session.snapshot.baseline?.result, 110))   // 150 never counted
    }

    @Test func canFinishEarly() {
        let session = makeSession()
        session.startBaseline()
        (oneRep(peak: 100) + oneRep(peak: 120, startingAt: 2)).forEach { session.process($0) }

        #expect(session.snapshot.baseline?.isFinished == false)
        session.finishBaseline()
        #expect(isClose(session.snapshot.baseline?.result, 110))
    }

    @Test func resultStaysFixedAfterFinishing() {
        let session = makeSession()
        session.startBaseline()
        let poses = oneRep(peak: 110) + oneRep(peak: 120, startingAt: 2) + oneRep(peak: 130, startingAt: 4)
            + oneRep(peak: 160, startingAt: 6)
        poses.forEach { session.process($0) }

        #expect(session.snapshot.repCount == 4)
        #expect(isClose(session.snapshot.baseline?.result, 120))
    }

    @Test func cancelClearsIt() {
        let session = makeSession()
        session.startBaseline()
        oneRep(peak: 110).forEach { session.process($0) }
        session.cancelBaseline()

        #expect(session.snapshot.baseline == nil)
        #expect(session.snapshot.repCount == 0)
    }
}
