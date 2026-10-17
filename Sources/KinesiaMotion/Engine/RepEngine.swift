//
//  RepEngine.swift
//  KinesiaMotion
//
//  Created by Deivy Mejia Ruiz on 4/10/26.
//

import Foundation

/// One finished repetition (or hold).
public struct Rep: Sendable, Equatable {
    /// Highest value of the rep. For a hold: the median of the held window.
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
    /// Hold exercises: the value settled above the threshold and the clock started.
    case holdStarted
    /// Live cue while moving: fired once per rep per fault.
    case formFault(FormFeedback)
    /// The required joints came into view or left it (debounced).
    case visibilityChanged(Visibility)
    /// The first measurement finished: median of the clean reps' peaks.
    case baselineCompleted(Double)
}

/// Turns a stream of poses into reps (or holds), checking form along the way.
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
    /// Hold exercises: how far (degrees) the value may drift before the hold clock restarts.
    public var holdTolerance = 5.0

    public private(set) var value: Double?
    public private(set) var best: Double = 0
    public private(set) var reps: [Rep] = []
    public private(set) var rejected: [Rep] = []
    /// Hold exercises: 0...1 while holding, nil otherwise. Drives a progress ring.
    public private(set) var holdProgress: Double?

    private var inRep = false
    private var repStart: TimeInterval = 0
    private var repPeak: Double = 0
    private var frames = 0
    private var faultFrames: [FormFeedback: Int] = [:]
    private var streaks: [FormFeedback: Int] = [:]
    private var cued: Set<FormFeedback> = []
    private var holdStart: TimeInterval?
    private var holdAnchor: Double = 0
    private var holdValues: [Double] = []
    private var holdDone = false

    public init(definition: ExerciseDefinition, side: BodySide) {
        self.definition = definition
        self.side = side
    }

    public var count: Int { reps.count }
    public var peaks: [Double] { reps.map(\.peak) }

    public mutating func process(_ pose: Pose) -> [MotionEvent] {
        guard let raw = definition.primary.value(in: pose, side: side) else { return [] }

        let smoothed = value.map { $0 + smoothing * (raw - $0) } ?? raw
        value = smoothed
        best = max(best, smoothed)

        switch definition.kind {
        case let .reps(low, high):
            return processRep(smoothed, at: pose, low: low, high: high)
        case let .hold(threshold, seconds):
            return processHold(smoothed, at: pose, threshold: threshold, seconds: seconds)
        }
    }

    private mutating func processRep(_ smoothed: Double, at pose: Pose, low: Double, high: Double) -> [MotionEvent] {
        var events: [MotionEvent] = []

        // Leaving rest: start watching this rep.
        if !inRep, smoothed > low {
            startAttempt(at: pose.timestamp, value: smoothed)
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
            events.append(judge(Rep(peak: repPeak, duration: pose.timestamp - repStart, faults: currentFaults)))
        }

        return events
    }

    /// Reach past `threshold`, stay within `holdTolerance` for `seconds`, then come back to rest.
    /// Dropping out before the clock runs out is ignored, like a partial rep.
    private mutating func processHold(_ smoothed: Double, at pose: Pose, threshold: Double, seconds: Double) -> [MotionEvent] {
        var events: [MotionEvent] = []

        guard smoothed > threshold else {
            inRep = false
            holdDone = false
            holdStart = nil
            holdProgress = nil
            return events
        }

        if !inRep {
            startAttempt(at: pose.timestamp, value: smoothed)
        }

        // One hold per trip: after it's judged, wait for rest before the next one.
        guard !holdDone else { return events }

        // Still climbing (or slipping back): restart the clock from here.
        if holdStart == nil || abs(smoothed - holdAnchor) > holdTolerance {
            if holdStart == nil { events.append(.holdStarted) }
            holdStart = pose.timestamp
            holdAnchor = smoothed
            holdValues = []
            frames = 0
            faultFrames = [:]
        }

        frames += 1
        holdValues.append(smoothed)
        events += checkForm(in: pose)

        let held = pose.timestamp - (holdStart ?? pose.timestamp)
        holdProgress = min(1, held / seconds)

        if held >= seconds, let median = holdValues.median {
            holdDone = true
            holdProgress = nil
            events.append(judge(Rep(peak: median, duration: held, faults: currentFaults)))
        }

        return events
    }

    private mutating func startAttempt(at time: TimeInterval, value: Double) {
        inRep = true
        repStart = time
        repPeak = value
        frames = 0
        faultFrames = [:]
        streaks = [:]
        cued = []
        holdStart = nil
        holdValues = []
        holdDone = false
    }

    /// Rules broken for more than `faultTolerance` of the frames.
    private var currentFaults: Set<FormFeedback> {
        Set(faultFrames.filter { Double($0.value) / Double(max(frames, 1)) > faultTolerance }.keys)
    }

    private mutating func judge(_ rep: Rep) -> MotionEvent {
        if rep.isClean {
            reps.append(rep)
            return .repCompleted(rep)
        } else {
            rejected.append(rep)
            return .repRejected(rep)
        }
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
        holdStart = nil
        holdValues = []
        holdDone = false
        holdProgress = nil
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
