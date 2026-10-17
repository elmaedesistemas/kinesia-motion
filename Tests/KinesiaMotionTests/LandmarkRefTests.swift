//
//  LandmarkRefTests.swift
//  KinesiaMotion
//
//  Created by Deivy Mejia Ruiz on 4/10/26.
//

import Foundation
import Testing
@testable import KinesiaMotion

@Suite("LandmarkRef")
struct LandmarkRefTests {
    @Test func activeSideResolves() {
        let ref: LandmarkRef = "elbow"
        #expect(ref.joint(for: .left) == .leftElbow)
        #expect(ref.joint(for: .right) == .rightElbow)
    }

    @Test func oppositeSideResolves() {
        let ref: LandmarkRef = "opposite.shoulder"
        #expect(ref.joint(for: .right) == .leftShoulder)
        #expect(ref.joint(for: .left) == .rightShoulder)
    }

    @Test func midlineIgnoresSide() {
        let ref: LandmarkRef = "neck"
        #expect(ref.joint(for: .left) == .neck)
        #expect(ref.joint(for: .right) == .neck)
    }

    @Test func invalidStringsAreRejected() {
        #expect(LandmarkRef(string: "elbo") == nil)
        #expect(LandmarkRef(string: "other.elbow") == nil)
        #expect(LandmarkRef(string: "opposite.elbow.extra") == nil)
    }

    @Test func encodesAsAPlainString() throws {
        let data = try JSONEncoder().encode(["opposite.hip" as LandmarkRef])
        #expect(String(decoding: data, as: UTF8.self) == #"["opposite.hip"]"#)
    }

    @Test func badJSONThrowsInsteadOfCrashing() {
        let data = Data(#"["elbo"]"#.utf8)
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode([LandmarkRef].self, from: data)
        }
    }
}
