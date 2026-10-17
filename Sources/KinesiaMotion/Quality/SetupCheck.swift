//
//  SetupCheck.swift
//  KinesiaMotion
//

import CoreGraphics

/// Something about how the patient stands in front of the camera that spoils the measurement.
/// The app turns each case into words and voice.
public enum SetupIssue: String, Sendable, CaseIterable, Codable {
    /// Side-view exercise, but the patient faces the camera: the angle is foreshortened.
    case turnSideways
    /// Front-view exercise, but the patient is turned sideways.
    case faceCamera
    /// The measured joints are tiny in the image: points jitter more.
    case moveCloser
    /// A measured joint is at the edge of the image and will leave it when moving.
    case stepBack
}

/// Judges the patient's placement from one pose. Pure and tunable.
public struct SetupCheck: Sendable {
    /// Shoulder width ÷ torso length above which a side view counts as facing the camera.
    public var maxSideRatio = 0.45
    /// Shoulder width ÷ torso length below which a front view counts as turned sideways.
    public var minFrontRatio = 0.35
    /// Span of the measured joints ÷ the image's shorter side, below which they're too small.
    public var minSpan = 0.15
    /// Margin (share of the image) a measured joint must keep from the edges.
    public var edgeMargin = 0.03

    public init() {}

    /// The issues seen on this pose. Anything it can't judge (a joint not in view,
    /// no image size) is left out rather than guessed.
    public func issues(in pose: Pose, exercise: ExerciseDefinition, side: BodySide) -> Set<SetupIssue> {
        var issues: Set<SetupIssue> = []

        if let ratio = shoulderRatio(in: pose, side: side) {
            switch exercise.view {
            case .side where ratio > maxSideRatio: issues.insert(.turnSideways)
            case .front where ratio < minFrontRatio: issues.insert(.faceCamera)
            default: break
            }
        }

        let points = exercise.joints(for: side).compactMap { pose[$0] }
        if let size = pose.imageSize, size.width > 0, size.height > 0, points.count > 1 {
            let xs = points.map(\.x), ys = points.map(\.y)
            let span = max(xs.max()! - xs.min()!, ys.max()! - ys.min()!)
            if Double(span / min(size.width, size.height)) < minSpan {
                issues.insert(.moveCloser)
            }

            let mx = size.width * edgeMargin, my = size.height * edgeMargin
            let nearEdge = points.contains {
                $0.x < mx || $0.x > size.width - mx || $0.y < my || $0.y > size.height - my
            }
            if nearEdge { issues.insert(.stepBack) }
        }

        return issues
    }

    /// How wide the shoulders look next to the torso: ~0.7 facing the camera, ~0.2 sideways.
    func shoulderRatio(in pose: Pose, side: BodySide) -> Double? {
        guard let left = pose[.leftShoulder], let right = pose[.rightShoulder] else { return nil }
        let torso = BodySide.allCases.compactMap { s -> Double? in
            guard let shoulder = pose[.shoulder(s)], let hip = pose[.hip(s)] else { return nil }
            return hypot(Double(shoulder.x - hip.x), Double(shoulder.y - hip.y))
        }.max()
        guard let torso, torso > 0 else { return nil }
        return hypot(Double(left.x - right.x), Double(left.y - right.y)) / torso
    }
}
