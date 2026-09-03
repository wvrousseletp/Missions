import SwiftUI
import SwiftData

struct MissionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var mission: Mission
    
    @State private var newStepTitle: String = ""
    @State private var showingDeleteAlert: Bool = false
    
    var body: some View {
        Form {
            Section(header: Text("Título da Missão")) {
                TextField("Título", text: $mission.title)
            }
            
            Section(header: Text("Anotações & Links")) {
                TextField("Adicione links de reuniões, documentos ou anotações livres...", text: $mission.details, axis: .vertical)
                    .lineLimit(3...8)
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
                        StepCardRow(step: step, mission: mission)
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
                
                Picker("Repetição", selection: $mission.recurrence) {
                    ForEach(Recurrence.allCases, id: \.self) { rec in
                        Text(rec.rawValue).tag(rec)
                    }
                }
                
                DatePicker("Data de Entrega", selection: Binding(
                    get: { mission.dueDate ?? Date() },
                    set: { mission.dueDate = $0 }
                ), displayedComponents: .date)
                
                Toggle(isOn: $mission.isAlarmMode) {
                    HStack {
                        Image(systemName: "bell.badge.wave.fill")
                            .foregroundStyle(.red)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Alerta em Tela Cheia")
                                .bold()
                            Text("Abre estilo despertador no horário")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            // SEÇÃO DE EXCLUSÃO DE MISSÃO
            Section {
                Button(role: .destructive, action: { showingDeleteAlert = true }) {
                    HStack {
                        Spacer()
                        Image(systemName: "trash.fill")
                        Text("Excluir Missão")
                            .bold()
                        Spacer()
                    }
                    .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Detalhes da Missão")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Excluir Missão?", isPresented: $showingDeleteAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Excluir", role: .destructive, action: deleteMission)
        } message: {
            Text("Esta ação não pode ser desfeita.")
        }
        .dismissKeyboardOnScroll()
    }
    
    private func deleteMission() {
        NotificationManager.shared.cancelNotification(for: mission)
        modelContext.delete(mission)
        try? modelContext.save()
        dismiss()
    }
    
    private func addStep() {
        let trimmed = newStepTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let lines = trimmed.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        var currentStepsCount = mission.steps?.count ?? 0
        for line in lines {
            let cleanTitle = line.replacingOccurrences(of: #"^[\-\*\•\d+\.]\s*"#, with: "", options: .regularExpression)
            guard !cleanTitle.isEmpty else { continue }
            
            let step = Step(title: cleanTitle, order: currentStepsCount)
            step.mission = mission
            modelContext.insert(step)
            currentStepsCount += 1
        }
        
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
