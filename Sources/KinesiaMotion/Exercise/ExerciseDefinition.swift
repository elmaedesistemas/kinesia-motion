//
//  ExerciseDefinition.swift
//  KinesiaMotion
//
//  Created by Deivy Mejia Ruiz on 4/10/26.
//

public enum BodyRegion: String, Sendable, CaseIterable, Codable {
    case neck, shoulder, elbow, wrist, back, hip, knee, ankle
}

/// Where the camera must see the patient from.
public enum CameraView: String, Sendable, Codable {
    case side, front
}

/// Everything the engine needs to know about one exercise. Pure data: JSON in, JSON out.
public struct ExerciseDefinition: Identifiable, Sendable, Hashable, Codable {
    public enum Kind: Sendable, Hashable, Codable {
        /// Move away from rest and come back. A rep counts when the movement
        /// passes `high` and then returns below `low` (hysteresis kills jitter).
        case reps(low: Double, high: Double)
    }

    /// Stable id, e.g. "elbow.flexion". Saved in sessions, never rename.
    public let id: String
    public let region: BodyRegion
    public let view: CameraView
    public let kind: Kind
    /// The main value: what we chart and compare with the target.
    public let primary: Measure
    public let rules: [FormRule]
    public let defaultTarget: Double

    public init(
        id: String,
        region: BodyRegion,
        view: CameraView,
        kind: Kind,
        primary: Measure,
        rules: [FormRule] = [],
        defaultTarget: Double
    ) {
        self.id = id
        self.region = region
        self.view = view
        self.kind = kind
        self.primary = primary
        self.rules = rules
        self.defaultTarget = defaultTarget
    }
}
