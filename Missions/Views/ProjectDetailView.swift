import SwiftUI
import SwiftData

struct ProjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var project: Project
    
    @State private var showingDeleteAlert = false
    @State private var showingQuickCapture = false
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
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
                .padding(.bottom, 80)
            }
            
            // BOTÃO FLUTUANTE `+` NO CANTO INFERIOR DIREITO PARA ADICIONAR MISSÃO AO PROJETO
            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                showingQuickCapture = true
            }) {
                Image(systemName: "plus")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: project.colorHex ?? "") ?? Color.accentColor, (Color(hex: project.colorHex ?? "") ?? Color.accentColor).opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: (Color(hex: project.colorHex ?? "") ?? Color.accentColor).opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 20)
            .padding(.bottom, 24)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showingDeleteAlert = true }) {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
            }
        }
        .alert("Excluir Projeto?", isPresented: $showingDeleteAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Excluir", role: .destructive, action: deleteProject)
        } message: {
            Text("Todas as missões vinculadas a este projeto serão excluídas.")
        }
        .sheet(isPresented: $showingQuickCapture) {
            QuickCaptureView(initialProject: project)
        }
    }
    
    private func deleteProject() {
        modelContext.delete(project)
        try? modelContext.save()
        dismiss()
    }
}
