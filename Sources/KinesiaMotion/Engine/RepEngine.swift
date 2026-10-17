//
//  RepEngine.swift
//  KinesiaMotion
//
//  Created by Deivy Mejia Ruiz on 4/10/26.
//

import Foundation

/// One finished repetition.
public struct Rep: Sendable, Equatable {
    public let peak: Double
    public let duration: TimeInterval
    /// Rules broken for a meaningful part of the rep. Empty = clean rep.
    public let faults: Set<FormFeedback>

    public var isClean: Bool { faults.isEmpty }
}

/// What happened on this frame. The app reacts (voice, haptics, UI).
public enum MotionEvent: Sendable, Equatable {
    case repCompleted(Rep)
    case repRejected(Rep)
    /// Live cue while moving: fired once per rep per fault.
    case formFault(FormFeedback)
    /// The required joints came into view or left it (debounced).
    case visibilityChanged(Visibility)
    /// The first measurement finished: median of the clean reps' peaks.
    case baselineCompleted(Double)
}

/// Turns a stream of poses into reps, checking form along the way.
/// Pure value type: no camera, no UI, fully testable.
public struct RepEngine: Sendable {
    public let definition: ExerciseDefinition
    public let side: BodySide

    /// Share of a rep's frames that may break a rule before the rep is rejected.
    public var faultTolerance = 0.2
    /// Consecutive bad frames before a live cue fires (~0.25 s at 24 FPS).
    public var framesToCue = 6
    /// EMA factor for the primary value. 1 = no smoothing.
    public var smoothing = 0.5

    public private(set) var value: Double?
    public private(set) var best: Double = 0
    public private(set) var reps: [Rep] = []
    public private(set) var rejected: [Rep] = []

    private var inRep = false
    private var repStart: TimeInterval = 0
    private var repPeak: Double = 0
    private var frames = 0
    private var faultFrames: [FormFeedback: Int] = [:]
    private var streaks: [FormFeedback: Int] = [:]
    private var cued: Set<FormFeedback> = []

    public init(definition: ExerciseDefinition, side: BodySide) {
        self.definition = definition
        self.side = side
    }

    public var count: Int { reps.count }
    public var peaks: [Double] { reps.map(\.peak) }

    public mutating func process(_ pose: Pose) -> [MotionEvent] {
        guard case let .reps(low, high) = definition.kind,
              let raw = definition.primary.value(in: pose, side: side) else { return [] }

        let smoothed = value.map { $0 + smoothing * (raw - $0) } ?? raw
        value = smoothed
        best = max(best, smoothed)

        var events: [MotionEvent] = []

        // Leaving rest: start watching this rep.
        if !inRep, smoothed > low {
            inRep = true
            repStart = pose.timestamp
            repPeak = smoothed
            frames = 0
            faultFrames = [:]
            streaks = [:]
            cued = []
        }

        guard inRep else { return events }

        frames += 1
        repPeak = max(repPeak, smoothed)
        events += checkForm(in: pose)

        // Back to rest: judge the rep.
        if smoothed < low {
            inRep = false
            // Small movements that never reached `high` are just ignored.
            guard repPeak >= high else { return events }

            let faults = Set(faultFrames.filter { Double($0.value) / Double(frames) > faultTolerance }.keys)
            let rep = Rep(peak: repPeak, duration: pose.timestamp - repStart, faults: faults)

            if rep.isClean {
                reps.append(rep)
                events.append(.repCompleted(rep))
            } else {
                rejected.append(rep)
                events.append(.repRejected(rep))
            }
        }

        return events
    }

    public mutating func reset() {
        value = nil
        best = 0
        reps = []
        rejected = []
        inRep = false
        frames = 0
        faultFrames = [:]
        streaks = [:]
        cued = []
    }

    private mutating func checkForm(in pose: Pose) -> [MotionEvent] {
        var events: [MotionEvent] = []
        for rule in definition.rules {
            guard let broken = rule.isBroken(in: pose, side: side) else { continue }
            let feedback = rule.feedback

            if broken {
                faultFrames[feedback, default: 0] += 1
                streaks[feedback, default: 0] += 1
                if streaks[feedback] == framesToCue, !cued.contains(feedback) {
                    cued.insert(feedback)
                    events.append(.formFault(feedback))
                }
            } else {
                streaks[feedback] = 0
            }
        }
        return events
    }
}
