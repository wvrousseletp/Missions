import SwiftUI
import SwiftData

struct MissionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var mission: Mission
    
    @State private var newStepTitle: String = ""
    
    var body: some View {
        Form {
            Section(header: Text("Título da Missão")) {
                TextField("Título", text: $mission.title)
            }
            
            Section(header: Text("Projeto e Setor")) {
                if let project = mission.project, let sector = project.sector {
                    HStack {
                        Image(systemName: sector.iconName)
                            .foregroundStyle(Color(hex: sector.colorHex) ?? .primary)
                        Text("\(sector.name) • \(project.name)")
                    }
                } else {
                    Text("Caixa de Entrada")
                        .foregroundStyle(.secondary)
                }
            }
            
            Section(header: Text("Checklist (Etapas)")) {
                if let steps = mission.steps?.sorted(by: { $0.order < $1.order }) {
                    ForEach(steps) { step in
                        StepRow(step: step, mission: mission)
                    }
                    .onDelete(perform: deleteSteps)
                    .onMove(perform: moveSteps)
                }
                
                HStack {
                    Image(systemName: "plus")
                        .foregroundColor(.accentColor)
                    TextField("Adicionar nova etapa", text: $newStepTitle)
                        .onSubmit {
                            addStep()
                        }
                }
            }
            
            Section(header: Text("Detalhes")) {
                Picker("Prioridade", selection: $mission.priority) {
                    Text("Baixa").tag(Priority.low)
                    Text("Média").tag(Priority.medium)
                    Text("Alta").tag(Priority.high)
                }
                
                DatePicker("Data de Entrega", selection: Binding(
                    get: { mission.dueDate ?? Date() },
                    set: { mission.dueDate = $0 }
                ), displayedComponents: .date)
            }
        }
        .navigationTitle("Detalhes da Missão")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func addStep() {
        let trimmed = newStepTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        let currentStepsCount = mission.steps?.count ?? 0
        let step = Step(title: trimmed, order: currentStepsCount)
        step.mission = mission
        modelContext.insert(step)
        
        newStepTitle = ""
        try? modelContext.save()
    }
    
    private func deleteSteps(offsets: IndexSet) {
        guard let steps = mission.steps?.sorted(by: { $0.order < $1.order }) else { return }
        for index in offsets {
            modelContext.delete(steps[index])
        }
        reorderSteps()
    }
    
    private func moveSteps(from source: IndexSet, to destination: Int) {
        guard var steps = mission.steps?.sorted(by: { $0.order < $1.order }) else { return }
        steps.move(fromOffsets: source, toOffset: destination)
        
        for (index, step) in steps.enumerated() {
            step.order = index
        }
        try? modelContext.save()
    }
    
    private func reorderSteps() {
        guard let steps = mission.steps?.sorted(by: { $0.order < $1.order }) else { return }
        for (index, step) in steps.enumerated() {
            step.order = index
        }
        try? modelContext.save()
    }
}
