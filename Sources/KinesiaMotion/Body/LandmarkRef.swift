//
//  LandmarkRef.swift
//  KinesiaMotion
//
//  Created by Deivy Mejia Ruiz on 4/10/26.
//

/// A body landmark relative to the exercised side, so one exercise works for left and right.
/// In JSON it's a plain string: "elbow" (active side) or "opposite.shoulder".
public struct LandmarkRef: Sendable, Hashable {
    public enum Landmark: String, Sendable, CaseIterable {
        case nose, neck, root, eye, ear, shoulder, elbow, wrist, hip, knee, ankle
    }

    public let landmark: Landmark
    public let isOpposite: Bool

    public init(_ landmark: Landmark, opposite: Bool = false) {
        self.landmark = landmark
        self.isOpposite = opposite
    }

    public init?(string: String) {
        let parts = string.split(separator: ".")
        switch parts.count {
        case 1:
            guard let landmark = Landmark(rawValue: String(parts[0])) else { return nil }
            self.init(landmark)
        case 2:
            guard parts[0] == "opposite", let landmark = Landmark(rawValue: String(parts[1])) else { return nil }
            self.init(landmark, opposite: true)
        default:
            return nil
        }
    }

    public var stringValue: String {
        isOpposite ? "opposite.\(landmark.rawValue)" : landmark.rawValue
    }

    /// The concrete joint once we know which side is being exercised.
    public func joint(for activeSide: BodySide) -> Joint {
        let side = isOpposite ? activeSide.opposite : activeSide
        switch landmark {
        case .nose: return .nose
        case .neck: return .neck
        case .root: return .root
        case .eye: return side == .left ? .leftEye : .rightEye
        case .ear: return .ear(side)
        case .shoulder: return .shoulder(side)
        case .elbow: return .elbow(side)
        case .wrist: return .wrist(side)
        case .hip: return .hip(side)
        case .knee: return .knee(side)
        case .ankle: return .ankle(side)
        }
    }
}

extension LandmarkRef: ExpressibleByStringLiteral {
    /// Lets the library write `"shoulder"` instead of `LandmarkRef(.shoulder)`.
    public init(stringLiteral value: String) {
        guard let ref = LandmarkRef(string: value) else {
            preconditionFailure("Unknown landmark: \(value)")
        }
        self = ref
    }
}

extension LandmarkRef: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let text = try container.decode(String.self)
        guard let ref = LandmarkRef(string: text) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unknown landmark '\(text)'"
            )
        }
        self = ref
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(stringValue)
    }
}
