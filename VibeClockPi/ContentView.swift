//
//  ClockView.swift
//  VibeClockPi
//
//  Created by Sam Grover on 3/30/25.
//

import SwiftUI
import OSLog // Add if you want logging within the view itself

struct ClockView: View {
  // State to hold the iterator for Pi digits
  // We store the iterator itself to maintain its state across fetches
  static private var piteratorIterator = Piterator().makeAsyncIterator()

  // State for the second hand's position (0-59)
  // Initialize lazily in .onAppear
  @State private var currentDate: Date = DateComponents(calendar:.current,  year: 2025, month: 3, day: 14, hour: 3, minute: 14, second: 15).date ?? Date(timeIntervalSince1970: 3600)

  // Logger (optional, but good for debugging async stuff)
  private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ClockApp", category: "ClockView")

  var body: some View {
    // TimelineView updates its content every second
    TimelineView(.periodic(from: currentDate, by: 1)) { context in
      // Get current real time components from the context
      let date = context.date
      let calendar = Calendar.current

      Canvas { graphicsContext, size in
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        // Use the smaller dimension for radius calculation, with some padding
        let radius = min(size.width, size.height) / 2 * 0.9

        // --- Draw Tick Marks ---
        drawTickMarks(context: graphicsContext, center: center, radius: radius)

        // --- Draw Hands ---
        // Pass the real hour/minute and the state-driven second
        drawHands(
          context: graphicsContext,
          center: center,
          radius: radius,
          hour: calendar.component(.hour, from: currentDate),
          minute: calendar.component(.minute, from: currentDate),
          second: calendar.component(.second, from: currentDate)
        )

        // --- Optional: Draw Center Circle ---
        let centerCircleRadius: CGFloat = radius * 0.05
        let centerCircleRect = CGRect(
          x: center.x - centerCircleRadius,
          y: center.y - centerCircleRadius,
          width: centerCircleRadius * 2,
          height: centerCircleRadius * 2
        )
        graphicsContext.fill(Path(ellipseIn: centerCircleRect), with: .color(.primary))

      }
      // Trigger fetching the next Pi digit and updating the state *after* this frame renders
      // using the date provided by the TimelineView context as the trigger.
      .onChange(of: date) { _,_ in // Use _ if newValue isn't needed directly
        Task {
          await fetchNextDigitAndUpdateSecond()
        }
      }
      // Optional: Add aspect ratio to keep it circular if desired
      // .aspectRatio(1, contentMode: .fit)
      // Optional: Add padding
      .padding()
    }
    .onAppear {
      // currentDate = startDate
      // Optionally, kick off the first fetch immediately if desired,
      // though onChange will trigger very soon anyway.
      // Task { await fetchNextDigitAndUpdateSecond() }
    }
  }

  // Async function to get the next digit and update state
  private func fetchNextDigitAndUpdateSecond() async {
    do {
      // Fetch the next digit from the iterator
      if let piDigit = try await ClockView.piteratorIterator.next() {
        Self.logger.debug("Fetched Pi digit: \(piDigit)")
        // Update the currentSecond state on the main thread
        // The new value wraps around using modulo 60
//        let second = Calendar.current.component(.second, from: currentDate)
//        let newSecond = (second + piDigit) % 60
        await MainActor.run { // Ensure UI updates happen on the main thread
          currentDate = Calendar.current.date(byAdding: .second, value: piDigit, to: currentDate) ?? Date()
          Self.logger.debug("Updated currentDate to: \(currentDate)")
        }
      } else {
        // Piterator finished or was cancelled
        Self.logger.info("Piterator returned nil (finished or cancelled).")
        // Decide what to do here: stop, loop, fetch from start?
        // For now, it will just stop advancing.
      }
    } catch {
      // Handle errors during fetch
      Self.logger.error("Error fetching next Pi digit: \(error.localizedDescription)")
      // Maybe set a default advancement or stop? For now, log and stop.
    }
  }

  // Helper function to draw all tick marks (Unchanged)
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

  // Helper function to draw the clock hands - MODIFIED to take time components
  private func drawHands(
    context: GraphicsContext,
    center: CGPoint,
    radius: CGFloat,
    hour: Int,    // Now a parameter
    minute: Int,  // Now a parameter
    second: Int   // Now a parameter
  ) {
    // --- Calculate Hand Angles ---
    // Note: -90 degrees aligns 0 angle with the 12 o'clock position.
    //       Angles increase clockwise.

    // Second Hand Angle (uses the passed-in 'second' which comes from state)
    let secondAngle = Angle.degrees(Double(second) / 60.0 * 360.0 - 90.0)

    // Minute Hand Angle (uses real minute)
    let minuteAngle = Angle.degrees(Double(minute) / 60.0 * 360.0 - 90.0)

    // Hour Hand Angle (uses real hour/minute for fractional part)
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
      angle: secondAngle, // Uses the angle calculated from our state-driven 'second'
      length: secondHandLength,
      color: .red, // Specific color for second hand
      width: secondHandWidth
    )
  }

  // Helper function to draw a single hand (Unchanged)
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
