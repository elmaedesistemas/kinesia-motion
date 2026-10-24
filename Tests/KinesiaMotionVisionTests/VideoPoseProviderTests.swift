//
//  VideoPoseProviderTests.swift
//  KinesiaMotion
//
//  Created by Deivy Mejia Ruiz on 24/10/26.
//

import Testing
import CoreGraphics
import ImageIO
import Foundation
@testable import KinesiaMotionVision

@Suite("VideoPoseProvider")
struct VideoPoseProviderTests {
    private let landscape = CGSize(width: 1920, height: 1080)

    @Test("a portrait iPhone video is rotated right and measured upright")
    func portrait() {
        let (orientation, size) = VideoPoseProvider.upright(transform: CGAffineTransform(rotationAngle: .pi / 2),
                                                            naturalSize: landscape)
        #expect(orientation == .right)
        #expect(size == CGSize(width: 1080, height: 1920))
    }

    @Test("an upside-down portrait video is rotated left")
    func portraitUpsideDown() {
        let (orientation, size) = VideoPoseProvider.upright(transform: CGAffineTransform(rotationAngle: -.pi / 2),
                                                            naturalSize: landscape)
        #expect(orientation == .left)
        #expect(size == CGSize(width: 1080, height: 1920))
    }

    @Test("landscape videos keep their size")
    func landscapeVideos() {
        let straight = VideoPoseProvider.upright(transform: .identity, naturalSize: landscape)
        #expect(straight.0 == .up && straight.1 == landscape)
        let flipped = VideoPoseProvider.upright(transform: CGAffineTransform(rotationAngle: .pi), naturalSize: landscape)
        #expect(flipped.0 == .down && flipped.1 == landscape)
    }

    @Test("a missing file throws instead of returning poses")
    func missingFile() async {
        let provider = VideoPoseProvider(url: URL(fileURLWithPath: "/nonexistent/video.mov"))
        await #expect(throws: (any Error).self) { try await provider.readAll() }
    }
}
