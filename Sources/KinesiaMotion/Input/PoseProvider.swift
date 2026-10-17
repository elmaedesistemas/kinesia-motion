//
//  PoseProvider.swift
//  KinesiaMotion
//
//  Created by Deivy Mejia Ruiz on 4/10/26.
//

/// Anything that produces poses: a live camera, a recording, a test.
///
/// Iterate the stream with `for await`. When the consumer stops iterating
/// (breaks out of the loop or cancels its task), the stream terminates and
/// the provider releases whatever it was using (e.g. turns the camera off).
public protocol PoseProvider: Sendable {
    /// A fresh stream of poses. Every call starts a new stream.
    func poses() -> AsyncStream<Pose>
}
