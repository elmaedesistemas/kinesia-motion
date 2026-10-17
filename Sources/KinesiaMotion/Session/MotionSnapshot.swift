//
//  MotionSnapshot.swift
//  KinesiaMotion
//
//  Created by Deivy Mejia Ruiz on 4/10/26.
//

/// Whether the joints an exercise needs are in view.
public struct Visibility: Sendable, Equatable {
    public let isVisible: Bool
    /// Empty when visible. Otherwise, what to ask the user to show.
    public let missingJoints: [Joint]
}

/// Progress of a first measurement ("baseline").
public struct BaselineProgress: Sendable, Equatable {
    public var repsDone: Int
    public let repsNeeded: Int
    /// Set when the measurement is finished.
    public var result: Double?

    public var isFinished: Bool { result != nil }
}

/// Everything a screen needs to draw the session, in one value.
public struct MotionSnapshot: Sendable, Equatable {
    /// Current smoothed value of the exercise's primary measure.
    public var value: Double?
    public var best: Double = 0
    public var repCount = 0
    public var rejectedCount = 0
    public var lastRep: Rep?
    /// Hold exercises: 0...1 while holding, nil otherwise.
    public var holdProgress: Double?
    public var isVisible = false
    public var missingJoints: [Joint] = []
    public var isRunning = false
    public var baseline: BaselineProgress?

    public init() {}
}
