import SwiftUI
import SwiftData

struct BacklogView: View {
    @Query(filter: #Predicate<Mission> { mission in
        mission.isCompleted == false
    }, sort: \Mission.createdAt, order: .reverse) var allPendingMissions: [Mission]
    
    var backlogMissions: [Mission] {
        allPendingMissions.filter { $0.dueDate == nil }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if backlogMissions.isEmpty {
                    ContentUnavailableView("Backlog Empty", systemImage: "tray", description: Text("All your missions are scheduled!"))
                } else {
                    ForEach(backlogMissions) { mission in
                        MissionRow(mission: mission)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Backlog")
        }
    }
}
