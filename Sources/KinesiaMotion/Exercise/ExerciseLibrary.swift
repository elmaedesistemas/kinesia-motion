//
//  ExerciseLibrary.swift
//  KinesiaMotion
//
//  Created by Deivy Mejia Ruiz on 4/10/26.
//

import Foundation

/// The built-in catalog. Each exercise is data, not code: adding one never touches the engine.
public enum ExerciseLibrary {

    /// Elbow flexion, standing, seen from the side.
    /// Form: the upper arm stays by the body, so the shoulder can't do the work.
    public static let elbowFlexion = ExerciseDefinition(
        id: "elbow.flexion",
        region: .elbow,
        view: .side,
        kind: .reps(low: 30, high: 90),
        primary: .flexion(a: "shoulder", vertex: "elbow", b: "wrist"),
        rules: [
            FormRule(
                feedback: .keepUpperArmStill,
                measure: .fromVertical(from: "shoulder", to: "elbow"),
                allowed: 0...30
            )
        ],
        defaultTarget: 120
    )

    /// Standing knee flexion (heel to glute), seen from the side.
    /// Form: the thigh stays vertical and the trunk upright, so it isn't a squat or a lean.
    public static let kneeFlexionStanding = ExerciseDefinition(
        id: "knee.flexion.standing",
        region: .knee,
        view: .side,
        kind: .reps(low: 20, high: 60),
        primary: .flexion(a: "hip", vertex: "knee", b: "ankle"),
        rules: [
            FormRule(
                feedback: .keepThighStill,
                measure: .fromVertical(from: "hip", to: "knee"),
                allowed: 0...25
            ),
            FormRule(
                feedback: .keepTrunkUpright,
                measure: .fromVertical(from: "shoulder", to: "hip"),
                allowed: 0...20
            )
        ],
        defaultTarget: 110
    )

    public static let all: [ExerciseDefinition] = [
        elbowFlexion,
        kneeFlexionStanding
    ]

    public static func definition(id: String) -> ExerciseDefinition? {
        all.first { $0.id == id }
    }

    public static func definitions(for region: BodyRegion) -> [ExerciseDefinition] {
        all.filter { $0.region == region }
    }

    // MARK: - JSON

    /// Reads exercises from JSON: a file bundled with the app today, a download tomorrow.
    public static func decode(from data: Data) throws -> [ExerciseDefinition] {
        try JSONDecoder().decode([ExerciseDefinition].self, from: data)
    }

    public static func encode(_ definitions: [ExerciseDefinition]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(definitions)
    }
}
