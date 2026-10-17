//
//  RecordedPoseProvider.swift
//  KinesiaMotion
//
//  Created by Deivy Mejia Ruiz on 4/10/26.
//

import Foundation

/// Replays a list of poses. For tests, demos without a camera, and debugging recorded sessions.
public struct RecordedPoseProvider: PoseProvider {
    public let recording: [Pose]
    /// true = wait between poses using their timestamps (looks live). false = as fast as possible.
    public let realTime: Bool

    public init(_ recording: [Pose], realTime: Bool = false) {
        self.recording = recording
        self.realTime = realTime
    }

    public func poses() -> AsyncStream<Pose> {
        let recording = recording
        let realTime = realTime

        return AsyncStream { continuation in
            let task = Task {
                var previous: TimeInterval?
                for pose in recording {
                    if Task.isCancelled { break }
                    if realTime, let previous {
                        let gap = max(0, pose.timestamp - previous)
                        if #available(macOS 13.0, *) {
                            if #available(iOS 16.0, *) {
                                try? await Task.sleep(for: .seconds(gap))
                            } else {
                                // Fallback on earlier versions
                            };if #available(iOS 16.0, *) {
                                try? await Task.sleep(for: .seconds(gap))
                            } else {
                                // Fallback on earlier versions
                            };if #available(iOS 16.0, *) {
                                try? await Task.sleep(for: .seconds(gap))
                            } else {
                                // Fallback on earlier versions
                            }
                        } else {
                            // Fallback on earlier versions
                        }
                    }
                    previous = pose.timestamp
                    continuation.yield(pose)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
