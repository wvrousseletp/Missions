import SwiftUI
import SwiftData

struct ProjectDetailView: View {
    @Bindable var project: Project
    
    var body: some View {
        List {
            Section {
                if !project.projectDescription.isEmpty {
                    Text(project.projectDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("Missões") {
                if let missions = project.missions, !missions.isEmpty {
                    ForEach(missions.sorted(by: { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) })) { mission in
                        MissionRow(mission: mission)
                    }
                } else {
                    Text("Nenhuma missão neste projeto ainda.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(project.name)
    }
}
