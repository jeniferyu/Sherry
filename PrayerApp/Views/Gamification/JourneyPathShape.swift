import SwiftUI

/// Draws a smooth curved path through a sequence of node center points using
/// Catmull-Rom-style quadratic Bezier approximation.
struct JourneyPathShape: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        guard points.count >= 2 else { return Path() }

        var p = Path()
        p.move(to: points[0])

        for i in 1..<points.count {
            let prev = points[i - 1]
            let curr = points[i]

            // Control point is biased toward the previous point to create a
            // smooth curve that bends naturally in the snake direction.
            let control = CGPoint(
                x: prev.x + (curr.x - prev.x) * 0.5,
                y: prev.y
            )
            p.addQuadCurve(to: curr, control: control)
        }

        return p
    }
}
