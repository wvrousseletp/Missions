import SwiftUI
import SwiftData

struct ProjectDetailView: View {
    @Bindable var project: Project
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if !project.projectDescription.isEmpty {
                    Text(project.projectDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Missões do Projeto")
                        .font(.headline)
                        .bold()
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                    
                    if let missions = project.missions, !missions.isEmpty {
                        ForEach(missions.sorted(by: { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) })) { mission in
                            MissionCard(mission: mission)
                        }
                    } else {
                        VStack(spacing: 8) {
                            Text("Nenhuma missão neste projeto ainda.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 20)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
