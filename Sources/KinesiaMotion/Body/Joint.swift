//
//  Joint.swift
//  KinesiaMotion
//
//  Created by Deivy Mejia Ruiz on 4/10/26.
//

/// The patient's anatomical side (their real left/right, never the mirrored one).
public enum BodySide: String, CaseIterable, Sendable, Codable {
    case left, right
    
    public var opposite: BodySide { self == .left ? .right : .left }
}

/// The 19 landmarks a 2D body-pose detector gives us.
public enum Joint: String, CaseIterable, Sendable {
    case nose, leftEye, rightEye, leftEar, rightEar, neck
    case leftShoulder, rightShoulder, leftElbow, rightElbow, leftWrist, rightWrist
    case root, leftHip, rightHip, leftKnee, rightKnee, leftAnkle, rightAnkle
    
    public static func ear(_ side: BodySide) -> Joint { side == .left ? .leftEar : .rightEar }
        public static func shoulder(_ side: BodySide) -> Joint { side == .left ? .leftShoulder : .rightShoulder }
        public static func elbow(_ side: BodySide) -> Joint { side == .left ? .leftElbow : .rightElbow }
        public static func wrist(_ side: BodySide) -> Joint { side == .left ? .leftWrist : .rightWrist }
        public static func hip(_ side: BodySide) -> Joint { side == .left ? .leftHip : .rightHip }
        public static func knee(_ side: BodySide) -> Joint { side == .left ? .leftKnee : .rightKnee }
        public static func ankle(_ side: BodySide) -> Joint { side == .left ? .leftAnkle : .rightAnkle }
}
