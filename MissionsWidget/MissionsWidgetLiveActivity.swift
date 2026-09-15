import ActivityKit
import WidgetKit
import SwiftUI

struct MissionActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var missionTitle: String
        var sectorName: String
        var sectorIcon: String
        var isCompleted: Bool
        var progress: Double
        var stepsCountText: String
    }
    
    var missionID: String
}

struct MissionsWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MissionActivityAttributes.self) { context in
            // TELA DE BLOQUEIO / NOTIFICAÇÃO AO VIVO
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.25))
                        .frame(width: 44, height: 44)
                    Image(systemName: context.state.sectorIcon.isEmpty ? "briefcase.fill" : context.state.sectorIcon)
                        .font(.title3)
                        .foregroundStyle(.purple)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(context.state.missionTitle)
                        .font(.headline)
                        .bold()
                        .lineLimit(1)
                        .foregroundStyle(.white)
                    
                    Text("\(context.state.sectorName) • \(context.state.stepsCountText)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                Spacer()
                
                if context.state.progress > 0 {
                    Text("\(Int(context.state.progress * 100))%")
                        .font(.caption)
                        .bold()
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.purple)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                } else {
                    Text("📌 Foco")
                        .font(.caption2)
                        .bold()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.3))
                        .foregroundStyle(.purple)
                        .clipShape(Capsule())
                }
            }
            .padding(16)
            .activityBackgroundTint(Color.black.opacity(0.85))
            .activitySystemActionForegroundColor(Color.purple)
        } dynamicIsland: { context in
            DynamicIsland {
                // DYNAMIC ISLAND EXPANDIDA (TOQUE LONGO)
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: context.state.sectorIcon.isEmpty ? "briefcase.fill" : context.state.sectorIcon)
                            .foregroundStyle(.purple)
                        Text(context.state.sectorName)
                            .font(.caption)
                            .bold()
                            .foregroundStyle(.white)
                    }
                    .padding(.leading, 8)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.stepsCountText)
                        .font(.caption2)
                        .bold()
                        .foregroundStyle(.purple)
                        .padding(.trailing, 8)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.missionTitle)
                        .font(.headline)
                        .bold()
                        .lineLimit(1)
                        .foregroundStyle(.white)
                        .padding(.top, 4)
                }
            } compactLeading: {
                HStack(spacing: 4) {
                    Image(systemName: "pin.fill")
                        .font(.caption2)
                        .foregroundStyle(.purple)
                    Image(systemName: context.state.sectorIcon.isEmpty ? "briefcase.fill" : context.state.sectorIcon)
                        .font(.caption2)
                        .foregroundStyle(.purple)
                }
            } compactTrailing: {
                Text(context.state.progress > 0 ? "\(Int(context.state.progress * 100))%" : "📌")
                    .font(.caption2)
                    .bold()
                    .foregroundStyle(.purple)
            } minimal: {
                Image(systemName: "pin.fill")
                    .font(.caption2)
                    .foregroundStyle(.purple)
            }
        }
    }
}
