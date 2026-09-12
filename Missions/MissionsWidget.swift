import WidgetKit
import SwiftUI
import ActivityKit
import SwiftData

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), missions: [
            Mission(title: "Apresentar projeto", priority: .high),
            Mission(title: "Comprar suprimentos", priority: .medium)
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), missions: [])
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = SimpleEntry(date: Date(), missions: [
            Mission(title: "Revisar relatórios", priority: .high),
            Mission(title: "Atualizar especificações", priority: .medium)
        ])
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let missions: [Mission]
}

struct MissionsWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Foco de Hoje")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
            
            if entry.missions.isEmpty {
                Text("Tudo em dia! 🚀")
                    .font(.headline)
            } else {
                ForEach(entry.missions.prefix(3)) { mission in
                    HStack {
                        Image(systemName: "circle")
                            .foregroundStyle(.gray)
                        Text(mission.title)
                            .font(.subheadline)
                            .lineLimit(1)
                    }
                }
            }
            Spacer()
        }
        .padding()
    }
}

struct MissionsWidget: Widget {
    let kind: String = "MissionsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                MissionsWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                MissionsWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Missões de Hoje")
        .description("Acompanhe suas principais prioridades do dia.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct MissionLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MissionActivityAttributes.self) { context in
            // TELA DE BLOQUEIO / NOTIFICAÇÃO AO VIVO
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.2))
                        .frame(width: 44, height: 44)
                    Image(systemName: context.state.sectorIcon)
                        .font(.title3)
                        .foregroundStyle(.purple)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(context.state.missionTitle)
                        .font(.headline)
                        .bold()
                        .lineLimit(1)
                    
                    Text("\(context.state.sectorName) • \(context.state.stepsCountText)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if context.state.progress > 0 {
                    Text("\(Int(context.state.progress * 100))%")
                        .font(.caption)
                        .bold()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.15))
                        .foregroundStyle(.purple)
                        .clipShape(Capsule())
                }
            }
            .padding(16)
            .activityBackgroundTint(Color.black.opacity(0.8))
        } dynamicIsland: { context in
            DynamicIsland {
                // DYNAMIC ISLAND EXPANDIDA (TOQUE LONGO)
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: context.state.sectorIcon)
                            .foregroundStyle(.purple)
                        Text(context.state.sectorName)
                            .font(.caption)
                            .bold()
                    }
                    .padding(.leading, 8)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.stepsCountText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.trailing, 8)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.missionTitle)
                        .font(.headline)
                        .bold()
                        .lineLimit(1)
                        .padding(.top, 4)
                }
            } compactLeading: {
                Image(systemName: context.state.sectorIcon)
                    .foregroundStyle(.purple)
            } compactTrailing: {
                Text(context.state.progress > 0 ? "\(Int(context.state.progress * 100))%" : "📌")
                    .font(.caption2)
                    .bold()
                    .foregroundStyle(.purple)
            } minimal: {
                Image(systemName: "pin.fill")
                    .foregroundStyle(.purple)
            }
        }
    }
}

struct MissionsWidgetBundle: WidgetBundle {
    var body: some Widget {
        MissionsWidget()
        MissionLiveActivityWidget()
    }
}
