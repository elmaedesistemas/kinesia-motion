
//
//  GeometryTests.swift
//  KinesiaMotion
//
//  Created by Deivy Mejia Ruiz on 4/10/26.
//
import CoreGraphics
import Testing
@testable import KinesiaMotion

@Suite("Geometry")
struct GeometryTests {
    private func close(_ value: Double?, _ expected: Double) -> Bool {
        guard let value else { return false }
        return abs(value - expected) < 0.001
    }

    @Test func rightAngle() {
        let value = Geometry.angle(at: .zero, CGPoint(x: 1, y: 0), CGPoint(x: 0, y: 1))
        #expect(close(value, 90))
    }

    @Test func straightLine() {
        let value = Geometry.angle(at: .zero, CGPoint(x: -1, y: 0), CGPoint(x: 1, y: 0))
        #expect(close(value, 180))
    }

    @Test func zeroLengthHasNoAngle() {
        #expect(Geometry.angle(at: .zero, .zero, CGPoint(x: 1, y: 0)) == nil)
    }

    @Test func fromVerticalFollowsImageCoordinates() {
        #expect(close(Geometry.fromVertical(.zero, CGPoint(x: 0, y: 10)), 0))     // down
        #expect(close(Geometry.fromVertical(.zero, CGPoint(x: 10, y: 0)), 90))    // horizontal
        #expect(close(Geometry.fromVertical(.zero, CGPoint(x: 0, y: -10)), 180))  // up
    }

    @Test func tiltIsMeasuredFromLevel() {
        #expect(close(Geometry.tilt(.zero, CGPoint(x: 10, y: 0)), 0))
        #expect(close(Geometry.tilt(.zero, CGPoint(x: 10, y: 10)), 45))
        #expect(close(Geometry.tilt(.zero, CGPoint(x: 0, y: 10)), 90))
    }
}
