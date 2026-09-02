import SwiftUI
import SwiftData

struct SectorDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var sector: Sector
    
    @State private var showingAddProject = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
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
                            .contextMenu {
                                Button(role: .destructive) {
                                    withAnimation {
                                        modelContext.delete(project)
                                        try? modelContext.save()
                                    }
                                } label: {
                                    Label("Excluir Projeto", systemImage: "trash")
                                }
                            }
                        }
                        .onDelete(perform: deleteProjects)
                    } else {
                        Text("Nenhum projeto ainda.")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .listStyle(.insetGrouped)
            
            // BOTÃO FLUTUANTE DE NOVO PROJETO (FAB)
            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                showingAddProject = true
            }) {
                Image(systemName: "plus")
                    .font(.title.bold())
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.accentColor.gradient)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 24)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showingDeleteAlert = true }) {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
            }
        }
        .alert("Excluir Setor?", isPresented: $showingDeleteAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Excluir", role: .destructive, action: deleteSector)
        } message: {
            Text("Todos os projetos e missões vinculados a este setor também serão excluídos.")
        }
        .sheet(isPresented: $showingAddProject) {
            AddProjectView(sector: sector)
        }
    }
    
    private func deleteSector() {
        modelContext.delete(sector)
        try? modelContext.save()
        dismiss()
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
