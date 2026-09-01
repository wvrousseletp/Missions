import SwiftUI
import SwiftData

struct WeekView: View {
    @Query(sort: \Mission.dueDate) var allMissions: [Mission]
    
    // Group by Day
    var missionsByDay: [(Date, [Mission])] {
        let calendar = Calendar.current
        var grouped: [Date: [Mission]] = [:]
        
        for mission in allMissions {
            if let dueDate = mission.dueDate {
                let startOfDay = calendar.startOfDay(for: dueDate)
                grouped[startOfDay, default: []].append(mission)
            }
        }
        
        return grouped.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if missionsByDay.isEmpty {
                    ContentUnavailableView("No Upcoming Missions", systemImage: "calendar.badge.clock", description: Text("Take a break or plan ahead!"))
                } else {
                    ForEach(missionsByDay, id: \.0) { date, missions in
                        Section(header: Text(date, style: .date).bold()) {
                            ForEach(missions) { mission in
                                MissionRow(mission: mission)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Upcoming")
        }
    }
}
