import WidgetKit
import SwiftUI
import SwiftData

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), missions: [
            Mission(title: "Finish project presentation", priority: .high),
            Mission(title: "Buy groceries", priority: .medium)
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), missions: [])
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // In a real scenario with App Groups, we would fetch from SwiftData here.
        // For now, we provide a placeholder timeline.
        let entry = SimpleEntry(date: Date(), missions: [
            Mission(title: "Review pull requests", priority: .high),
            Mission(title: "Update design specs", priority: .medium)
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
            Text("Today's Focus")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
            
            if entry.missions.isEmpty {
                Text("All clear! 🚀")
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

@main
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
        .configurationDisplayName("Today's Missions")
        .description("Keep track of your top priorities for the day.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
