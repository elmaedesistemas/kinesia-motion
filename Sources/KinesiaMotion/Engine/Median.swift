//
//  Median.swift
//  KinesiaMotion
//
//  Created by Deivy Mejia Ruiz on 4/10/26.
//

extension Array where Element == Double {
    /// Middle value; average of the two middle values when the count is even.
    var median: Double? {
        guard !isEmpty else { return nil }
        let sorted = sorted()
        let middle = sorted.count / 2
        return sorted.count.isMultiple(of: 2)
            ? (sorted[middle - 1] + sorted[middle]) / 2
            : sorted[middle]
    }
}
