import SwiftUI
import SwiftData

struct SectorDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var sector: Sector
    
    @State private var showingAddProject = false
    
    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: sector.iconName)
                        .font(.largeTitle)
                        .foregroundStyle(Color(hex: sector.colorHex) ?? .primary)
                    Text(sector.name)
                        .font(.title)
                        .bold()
                }
                .padding(.vertical, 8)
            }
            
            Section("Projetos") {
                if let projects = sector.projects, !projects.isEmpty {
                    ForEach(projects.sorted(by: { $0.createdAt > $1.createdAt })) { project in
                        NavigationLink(destination: ProjectDetailView(project: project)) {
                            VStack(alignment: .leading) {
                                Text(project.name).font(.headline)
                                if !project.projectDescription.isEmpty {
                                    Text(project.projectDescription)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete(perform: deleteProjects)
                } else {
                    Text("Nenhum projeto ainda.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(sector.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    showingAddProject = true
                }) {
                    Image(systemName: "folder.badge.plus")
                }
            }
        }
        .sheet(isPresented: $showingAddProject) {
            AddProjectView(sector: sector)
        }
    }
    
    private func deleteProjects(offsets: IndexSet) {
        guard let projects = sector.projects else { return }
        let sorted = projects.sorted(by: { $0.createdAt > $1.createdAt })
        withAnimation {
            for index in offsets {
                modelContext.delete(sorted[index])
            }
            try? modelContext.save()
        }
    }
}
