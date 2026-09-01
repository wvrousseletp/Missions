import SwiftUI
import SwiftData

struct QuickCaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query var projects: [Project]
    
    @State private var title: String = ""
    @State private var priority: Priority = .medium
    @State private var dueDate: Date = Date()
    @State private var hasDueDate: Bool = true
    @State private var selectedProject: Project?
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("O que precisa ser feito?", text: $title)
                        .font(.headline)
                        .padding(.vertical, 8)
                }
                
                Section {
                    if !projects.isEmpty {
                        Picker("Projeto", selection: $selectedProject) {
                            Text("Nenhum").tag(Project?.none)
                            ForEach(projects) { project in
                                Text("\(project.sector?.name ?? "") • \(project.name)").tag(Project?.some(project))
                            }
                        }
                    }
                }
                
                Section {
                    Picker("Prioridade", selection: $priority) {
                        Text("Baixa").tag(Priority.low)
                        Text("Média").tag(Priority.medium)
                        Text("Alta").tag(Priority.high)
                    }
                    .pickerStyle(.segmented)
                    
                    Toggle("Definir Data", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("Data", selection: $dueDate, displayedComponents: .date)
                    }
                }
                
                Section {
                    Button(action: saveMission) {
                        Text("Salvar Missão")
                            .frame(maxWidth: .infinity)
                            .bold()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Captura Rápida")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }
    
    private func saveMission() {
        let newMission = Mission(
            title: title,
            dueDate: hasDueDate ? dueDate : nil,
            priority: priority
        )
        newMission.project = selectedProject
        modelContext.insert(newMission)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving mission: \(error)")
        }
    }
}
