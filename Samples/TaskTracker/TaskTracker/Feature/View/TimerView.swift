//
//  TimerView.swift
//  TaskTracker
//
//  Created by Thibault Wittemberg on 13/02/2022.
//

import Combine
import SwiftUI

struct TimerView: View {
  // MARK: private properties
  private var formatter: DateComponentsFormatter {
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = .positional
    formatter.zeroFormattingBehavior = .pad
    formatter.allowedUnits = [.hour, .minute, .second]
    return formatter
  }

  @Namespace private var animation
  @SwiftUI.State private var timerSubscription: Cancellable?
  @SwiftUI.State private var timer = Timer.publish(every: 1, on: .main, in: .common)
  @SwiftUI.State private var start = Date.now
  @SwiftUI.State private var now = Date.now
  @SwiftUI.State private var isStarted = false
  @FocusState private var descriptionIsFocused: Bool

  private var timeInterval: TimeInterval {
    self.now.timeIntervalSince(self.start)
  }

  // MARK: public properties
  @SwiftUI.State var description: String = ""
  let onStop: (Date, Date, String) -> Void

  var body: some View {
    HStack(spacing: 24) {
      if self.isStarted {
        // display the stop button
        self.makeTimerButton(systemName: "stop.fill",
                             startGradientColor: Color("TimerButtonStopStartGradient"),
                             endGradientColor: Color("TimerButtonStopEndGradient"),
                             strokeColor: Color("TimerButtonStroke")) {
          self.timerSubscription?.cancel()
          withAnimation(.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.2)) {
            self.isStarted = false
          }
          self.onStop(self.start, self.now, self.description)
          self.description = ""
          self.start = .now
          self.now = self.start
        }
      }

      VStack(alignment: .leading) {
        Text(formatter.string(from: self.timeInterval)!)
          .monospacedDigit()
          .font(.largeTitle)
          .fontWeight(.bold)
          .foregroundColor(Color("TimerTextForeground"))
          .opacity(self.isStarted ? 1.0 :0.5)

        TextField("Description", text: self.$description, prompt: Text("I'm working on..."))
          .textFieldStyle(.roundedBorder)
          .focused(self.$descriptionIsFocused)
      }

      if !self.isStarted {
        // display the start button
        self.makeTimerButton(systemName: "play.fill",
                             startGradientColor: Color("TimerButtonPlayStartGradient"),
                             endGradientColor: Color("TimerButtonPlayEndGradient"),
                             strokeColor: Color("TimerButtonStroke")) {
          self.start = .now
          self.now = self.start
          self.timer = Timer.publish(every: 1, on: .main, in: .common)
          self.timerSubscription = self.timer.connect()
          withAnimation(.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.2)) {
            self.isStarted = true
          }
        }
      }
    }
    .padding(30)
    .onReceive(self.timer) { _ in
      self.now = Date()
    }
  }

  private func makeTimerButton(systemName: String,
                               startGradientColor: Color,
                               endGradientColor: Color,
                               strokeColor: Color,
                               onTap: @escaping () -> Void) -> some View {
    Button {
      self.descriptionIsFocused = false
      onTap()
    } label: {
      Circle()
        .foregroundColor(Color.clear)
        .background(
          RadialGradient(colors: [startGradientColor, endGradientColor],
                         center: .center,
                         startRadius: 0,
                         endRadius: 50)
        )
        .overlay(
          Circle()
            .trim(from: 0, to: self.timeInterval.truncatingRemainder(dividingBy: 60) / 60)
            .stroke(strokeColor.opacity(0.7), lineWidth: 15)
            .animation(.default, value: self.timeInterval)
        )
        .overlay(
          Image(systemName: systemName)
            .font(.system(size: 30, weight: .bold, design: .rounded))
            .foregroundColor(.white)
        )
    }
    .frame(width: 80, height: 80)
    .clipShape(Circle())
    .matchedGeometryEffect(id: "button", in: self.animation)
    .shadow(radius: 5)
  }
}

struct TimerView_Previews: PreviewProvider {
  static var previews: some View {
    TimerView(onStop: { _, _, _ in })
      .previewLayout(.sizeThatFits)
  }
}
