//
//  Measure.swift
//  KinesiaMotion
//
//  Created by Deivy Mejia Ruiz on 4/10/26.
//

import CoreGraphics

/// Something we can read from a pose, in degrees. Pure data: it can live in JSON.
public enum Measure: Sendable, Hashable, Codable {
    /// Inner angle at `vertex` (0...180).
    case angle(a: LandmarkRef, vertex: LandmarkRef, b: LandmarkRef)
    /// 180 − inner angle: 0 = straight limb, grows as it bends.
    case flexion(a: LandmarkRef, vertex: LandmarkRef, b: LandmarkRef)
    /// Segment from→to against straight down (0 down, 90 horizontal, 180 up).
    case fromVertical(from: LandmarkRef, to: LandmarkRef)
    /// Line between two landmarks against level (0 level, 90 vertical).
    case tilt(a: LandmarkRef, b: LandmarkRef)

    public func value(in pose: Pose, side: BodySide) -> Double? {
        func point(_ ref: LandmarkRef) -> CGPoint? { pose[ref.joint(for: side)] }

        switch self {
        case let .angle(a, vertex, b):
            guard let pa = point(a), let pv = point(vertex), let pb = point(b) else { return nil }
            return Geometry.angle(at: pv, pa, pb)

        case let .flexion(a, vertex, b):
            return Measure.angle(a: a, vertex: vertex, b: b)
                .value(in: pose, side: side)
                .map { 180 - $0 }

        case let .fromVertical(from, to):
            guard let pf = point(from), let pt = point(to) else { return nil }
            return Geometry.fromVertical(pf, pt)

        case let .tilt(a, b):
            guard let pa = point(a), let pb = point(b) else { return nil }
            return Geometry.tilt(pa, pb)
        }
    }

    /// The joints this measure needs to see. Used for "show your whole arm" guidance.
    public func joints(for side: BodySide) -> [Joint] {
        let refs: [LandmarkRef]
        switch self {
        case let .angle(a, vertex, b), let .flexion(a, vertex, b): refs = [a, vertex, b]
        case let .fromVertical(from, to): refs = [from, to]
        case let .tilt(a, b): refs = [a, b]
        }
        return refs.map { $0.joint(for: side) }
    }
}
