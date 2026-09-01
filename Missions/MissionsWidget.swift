import WidgetKit
import SwiftUI
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
        .configurationDisplayName("Missões de Hoje")
        .description("Acompanhe suas principais prioridades do dia.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
