//
//  ClockView.swift
//  VibeClockPi
//
//  Created by Sam Grover on 3/30/25.
//

import SwiftUI

struct ClockView: View {
  // Fixed time for this example
  let hour: Int = 10
  let minute: Int = 10
  let second: Int = 30

  var body: some View {
    Canvas { context, size in
      let center = CGPoint(x: size.width / 2, y: size.height / 2)
      // Use the smaller dimension for radius calculation, with some padding
      let radius = min(size.width, size.height) / 2 * 0.9

      // --- Draw Tick Marks ---
      drawTickMarks(context: context, center: center, radius: radius)

      // --- Draw Hands ---
      drawHands(context: context, center: center, radius: radius)

      // --- Optional: Draw Center Circle ---
      let centerCircleRadius: CGFloat = radius * 0.05
      let centerCircleRect = CGRect(
        x: center.x - centerCircleRadius,
        y: center.y - centerCircleRadius,
        width: centerCircleRadius * 2,
        height: centerCircleRadius * 2
      )
      context.fill(Path(ellipseIn: centerCircleRect), with: .color(.primary))

    }
    // Optional: Add aspect ratio to keep it circular if desired
    // .aspectRatio(1, contentMode: .fit)
    // Optional: Add padding
    .padding()
  }

  // Helper function to draw all tick marks
  private func drawTickMarks(context: GraphicsContext, center: CGPoint, radius: CGFloat) {
    for i in 0..<60 {
      let angle = Angle.degrees(Double(i) * 6.0 - 90) // -90 to make 0 degrees point up

      let isHourMark = (i % 5 == 0)
      let tickLength = isHourMark ? radius * 0.1 : radius * 0.05
      let tickWidth: CGFloat = isHourMark ? 2.5 : 1.0

      let startX = center.x + radius * cos(angle.radians)
      let startY = center.y + radius * sin(angle.radians)
      let endX = center.x + (radius - tickLength) * cos(angle.radians)
      let endY = center.y + (radius - tickLength) * sin(angle.radians)

      var path = Path()
      path.move(to: CGPoint(x: startX, y: startY))
      path.addLine(to: CGPoint(x: endX, y: endY))

      context.stroke(path, with: .color(.primary), lineWidth: tickWidth)
    }
  }

  // Helper function to draw the clock hands
  private func drawHands(context: GraphicsContext, center: CGPoint, radius: CGFloat) {
    // --- Calculate Hand Angles ---
    // Note: -90 degrees aligns 0 angle with the 12 o'clock position.
    //       Angles increase clockwise.

    // Second Hand Angle
    let secondAngle = Angle.degrees(Double(second) / 60.0 * 360.0 - 90.0)

    // Minute Hand Angle
    let minuteAngle = Angle.degrees(Double(minute) / 60.0 * 360.0 - 90.0)

    // Hour Hand Angle (includes fractional part based on minutes)
    let hourAngle = Angle.degrees(
      (Double(hour % 12) + Double(minute) / 60.0) / 12.0 * 360.0 - 90.0
    )

    // --- Define Hand Properties ---
    let hourHandLength = radius * 0.5
    let minuteHandLength = radius * 0.7
    let secondHandLength = radius * 0.85 // Often the longest

    let hourHandWidth: CGFloat = 6.0
    let minuteHandWidth: CGFloat = 4.0
    let secondHandWidth: CGFloat = 2.0

    // --- Draw Hour Hand ---
    drawHand(
      context: context,
      center: center,
      angle: hourAngle,
      length: hourHandLength,
      color: .primary,
      width: hourHandWidth
    )

    // --- Draw Minute Hand ---
    drawHand(
      context: context,
      center: center,
      angle: minuteAngle,
      length: minuteHandLength,
      color: .primary,
      width: minuteHandWidth
    )

    // --- Draw Second Hand ---
    drawHand(
      context: context,
      center: center,
      angle: secondAngle,
      length: secondHandLength,
      color: .red, // Specific color for second hand
      width: secondHandWidth
    )
  }

  // Helper function to draw a single hand
  private func drawHand(
    context: GraphicsContext,
    center: CGPoint,
    angle: Angle,
    length: CGFloat,
    color: Color,
    width: CGFloat
  ) {
    let endX = center.x + length * cos(angle.radians)
    let endY = center.y + length * sin(angle.radians)

    var path = Path()
    path.move(to: center)
    path.addLine(to: CGPoint(x: endX, y: endY))

    context.stroke(
      path,
      with: .color(color),
      style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round) // Rounded caps look nice
    )
  }
}

// --- Preview Provider ---
#Preview {
  ClockView()
    .frame(width: 300, height: 300) // Give it a size for the preview
}
