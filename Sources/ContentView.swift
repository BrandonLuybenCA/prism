import SwiftUI
import ActivityKit

struct ContentView: View {
    @State private var remainingSeconds = 25 * 60
    @State private var totalSeconds = 25 * 60
    @State private var isRunning = false
    @State private var timer: Timer?
    @State private var activity: Activity<PrismAttributes>?
    
    @State private var gradientPhase: Double = 0
    
    let timerPublisher = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    var progress: Double {
        1 - Double(remainingSeconds) / Double(totalSeconds)
    }
    
    var formattedTime: String {
        let mins = remainingSeconds / 60
        let secs = remainingSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    var body: some View {
        ZStack {
            // Animated gradient background
            TimelineView(.animation) { timeline in
                let phase = timeline.date.timeIntervalSince1970.truncatingRemainder(dividingBy: 12) / 12
                
                LinearGradient(
                    colors: [
                        Color(red: 0.06, green: 0.13, blue: 0.15).mix(with: Color(red: 0.17, green: 0.32, blue: 0.39), by: phase),
                        Color(red: 0.13, green: 0.23, blue: 0.26).mix(with: Color(red: 0.11, green: 0.71, blue: 0.88), by: phase),
                        Color(red: 0.17, green: 0.32, blue: 0.39).mix(with: Color(red: 0.00, green: 0.00, blue: 0.27), by: phase)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
            
            // Floating glass orbs
            GlassOrb(size: 90, offset: CGPoint(x: -130, y: -250), delay: 0)
            GlassOrb(size: 70, offset: CGPoint(x: 150, y: 200), delay: 0.5)
            GlassOrb(size: 50, offset: CGPoint(x: 120, y: -150), delay: 0.3)
            
            // Main content
            VStack {
                HStack {
                    Text("Prism")
                        .font(.system(size: 34, weight: .thin))
                        .foregroundColor(.white.opacity(0.7))
                        .kerning(6)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                
                Spacer()
                
                // Timer card
                TimerCard(
                    progress: progress,
                    formattedTime: formattedTime,
                    isRunning: isRunning,
                    onToggle: toggleTimer,
                    onReset: resetTimer
                )
                
                Spacer()
            }
        }
        .onReceive(timerPublisher) { _ in
            // Animate nothing — just triggers redraw
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            guard isRunning else { return }
            if remainingSeconds > 0 {
                remainingSeconds -= 1
                updateLiveActivity()
            } else {
                stopTimer()
                showNotification()
            }
        }
    }
    
    func toggleTimer() {
        if isRunning {
            stopTimer()
        } else {
            startTimer()
        }
    }
    
    func startTimer() {
        isRunning = true
        startLiveActivity()
    }
    
    func stopTimer() {
        isRunning = false
        endLiveActivity()
    }
    
    func resetTimer() {
        stopTimer()
        remainingSeconds = totalSeconds
    }
    
    func startLiveActivity() {
        let attributes = PrismAttributes()
        let state = PrismAttributes.ContentState(
            remainingSeconds: remainingSeconds,
            totalSeconds: totalSeconds,
            progress: progress,
            formattedTime: formattedTime
        )
        
        do {
            activity = try Activity.request(attributes: attributes, contentState: state)
        } catch {
            print("Live Activity error: \(error)")
        }
    }
    
    func updateLiveActivity() {
        guard let activity = activity else { return }
        
        let state = PrismAttributes.ContentState(
            remainingSeconds: remainingSeconds,
            totalSeconds: totalSeconds,
            progress: progress,
            formattedTime: formattedTime
        )
        
        Task {
            await activity.update(using: state)
        }
    }
    
    func endLiveActivity() {
        guard let activity = activity else { return }
        
        Task {
            await activity.end(dismissalPolicy: .immediate)
        }
        self.activity = nil
    }
    
    func showNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Prism"
        content.body = "Time's up — take a break"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Timer Card
struct TimerCard: View {
    let progress: Double
    let formattedTime: String
    let isRunning: Bool
    let onToggle: () -> Void
    let onReset: () -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 50)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 50)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
                )
                .overlay(
                    LinearGradient(
                        colors: [Color.white.opacity(0.15), Color.white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 50))
                )
            
            VStack(spacing: 0) {
                PrismLogo(size: 80)
                    .padding(.top, 40)
                
                Spacer()
                    .frame(height: 25)
                
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 6)
                        .frame(width: 200, height: 200)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.white.opacity(0.6), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                    
                    Text(formattedTime)
                        .font(.system(size: 48, weight: .thin))
                        .foregroundColor(.white)
                        .kerning(4)
                }
                
                Spacer()
                    .frame(height: 30)
                
                HStack(spacing: 20) {
                    ControlButton(icon: isRunning ? "pause.fill" : "play.fill", action: onToggle)
                    ControlButton(icon: "arrow.counterclockwise", action: onReset)
                }
                .padding(.bottom, 40)
            }
        }
        .frame(width: 320)
        .fixedSize()
    }
}

// MARK: - Control Button
struct ControlButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .background(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Glass Orb
struct GlassOrb: View {
    let size: CGFloat
    let offset: CGPoint
    let delay: Double
    
    @State private var phase: Double = 0
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSince1970 + delay
            let position = sin(time / 8) * 20
            
            Circle()
                .fill(.ultraThinMaterial)
                .background(
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .frame(width: size, height: size)
                .offset(x: offset.x + position, y: offset.y + sin(time / 6) * 15)
                .blur(radius: 0.5)
        }
    }
}

// MARK: - Prism Logo
struct PrismLogo: View {
    let size: CGFloat
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.2)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: size * 0.2)
                        .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
                )
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.cyan.opacity(0.4),
                            Color.purple.opacity(0.3),
                            Color.blue.opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.2))
                )
            
            PrismShape()
                .stroke(Color.white.opacity(0.8), lineWidth: 2.5)
                .frame(width: size * 0.5, height: size * 0.45)
            
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(width: size * 0.1, height: size * 0.2)
                .offset(y: size * 0.15)
        }
        .frame(width: size, height: size)
    }
}

struct PrismShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX * 0.8, y: rect.maxY * 0.7))
        path.addLine(to: CGPoint(x: rect.maxX * 0.2, y: rect.maxY * 0.7))
        path.closeSubpath()
        return path
    }
}

// MARK: - Live Activities Attributes
struct PrismAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var remainingSeconds: Int
        var totalSeconds: Int
        var progress: Double
        var formattedTime: String
    }
}

// MARK: - Color Extension
extension Color {
    func mix(with other: Color, by amount: Double) -> Color {
        let amount = max(0, min(1, amount))
        
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        UIColor(self).getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        UIColor(other).getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        return Color(
            red: r1 + (r2 - r1) * amount,
            green: g1 + (g2 - g1) * amount,
            blue: b1 + (b2 - b1) * amount,
            opacity: a1 + (a2 - a1) * amount
        )
    }
}
