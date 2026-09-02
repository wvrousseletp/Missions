import SwiftUI
import SwiftData

@main
struct MissionsApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Sector.self,
            Project.self,
            Mission.self,
            Step.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, Locale(identifier: "pt_BR"))
        }
        .modelContainer(sharedModelContainer)
    }
}
