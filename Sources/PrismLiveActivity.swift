import ActivityKit
import WidgetKit
import SwiftUI

struct PrismLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PrismAttributes.self) { context in
            // Lock Screen view
            HStack(spacing: 16) {
                Image(systemName: "triangle")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cyan, .purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Prism")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    ProgressView(value: context.state.progress)
                        .tint(.white.opacity(0.6))
                        .background(Color.white.opacity(0.1))
                        .frame(width: 150)
                }
                
                Spacer()
                
                Text(context.state.formattedTime)
                    .font(.title2)
                    .fontWeight(.thin)
                    .monospacedDigit()
                    .foregroundColor(.white)
            }
            .padding()
            .background(.ultraThinMaterial)
            .containerBackground(.clear, for: .widget)
            
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "triangle")
                        .foregroundStyle(.cyan.gradient)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.formattedTime)
                        .font(.title2)
                        .fontWeight(.thin)
                        .monospacedDigit()
                }
                DynamicIslandExpandedRegion(.center) {
                    ProgressView(value: context.state.progress)
                        .tint(.white.opacity(0.6))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Focus Session")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } compactLeading: {
                Image(systemName: "triangle")
                    .foregroundStyle(.cyan.gradient)
            } compactTrailing: {
                Text(context.state.formattedTime)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .monospacedDigit()
            } minimal: {
                Image(systemName: "triangle")
                    .foregroundStyle(.cyan.gradient)
            }
        }
    }
}
