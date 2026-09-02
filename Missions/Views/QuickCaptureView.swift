import SwiftUI
import SwiftData
import Speech
import AVFoundation

struct QuickCaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query var projects: [Project]
    
    @State private var title: String = ""
    @State private var details: String = ""
    @State private var priority: Priority = .medium
    @State private var recurrence: Recurrence = .none
    @State private var estimatedMinutes: Int = 30
    @State private var hasEstimatedTime: Bool = false
    @State private var dueDate: Date = Date()
    @State private var hasDueDate: Bool = true
    @State private var includeTime: Bool = false
    @State private var selectedProject: Project?
    
    // Checklist/Subtarefas diretamente na captura
    @State private var newStepTitle: String = ""
    @State private var tempSteps: [String] = []
    
    // Reconhecimento de voz
    @State private var isListening = false
    @StateObject private var speechManager = SpeechManager()
    
    var body: some View {
        NavigationStack {
            Form {
                // TÍTULO E NOTAS (ESTILO APPLE REMINDERS)
                Section {
                    HStack {
                        TextField("Título da missão", text: $title)
                            .font(.headline)
                        
                        Button(action: toggleSpeech) {
                            Image(systemName: isListening ? "mic.fill" : "mic")
                                .foregroundStyle(isListening ? .red : .accentColor)
                                .font(.title2)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    TextField("Notas, links de reuniões ou detalhes...", text: $details, axis: .vertical)
                        .font(.subheadline)
                        .lineLimit(2...5)
                }
                
                // ATALHOS RÁPIDOS DE DATA
                Section(header: Text("Data e Hora")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            QuickDateChip(title: "Hoje", icon: "sun.max.fill", color: .orange) {
                                hasDueDate = true
                                dueDate = Date()
                            }
                            
                            QuickDateChip(title: "Amanhã", icon: "sunrise.fill", color: .purple) {
                                hasDueDate = true
                                dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                            }
                            
                            QuickDateChip(title: "Fim de Semana", icon: "sofa.fill", color: .blue) {
                                hasDueDate = true
                                dueDate = nextWeekend()
                            }
                            
                            QuickDateChip(title: "Sem Data", icon: "tray.fill", color: .gray) {
                                hasDueDate = false
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    Toggle("Definir Data Específica", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("Data", selection: $dueDate, displayedComponents: includeTime ? [.date, .hourAndMinute] : [.date])
                        
                        Toggle("Incluir Horário", isOn: $includeTime)
                    }
                }
                
                // RECORRÊNCIA E ESTIMATIVA DE TEMPO
                Section(header: Text("Planejamento & Repetição")) {
                    Picker("Repetição", selection: $recurrence) {
                        ForEach(Recurrence.allCases, id: \.self) { rec in
                            Text(rec.rawValue).tag(rec)
                        }
                    }
                    
                    Toggle("Definir Estimativa de Tempo", isOn: $hasEstimatedTime)
                    
                    if hasEstimatedTime {
                        Stepper("\(estimatedMinutes) minutos de foco", value: $estimatedMinutes, in: 5...240, step: 15)
                    }
                }
                
                // CHECKLIST / SUBTAREFAS
                Section(header: Text("Checklist (Subtarefas)")) {
                    ForEach(tempSteps.indices, id: \.self) { index in
                        HStack {
                            Image(systemName: "circle")
                                .foregroundStyle(.gray)
                            Text(tempSteps[index])
                            Spacer()
                        }
                    }
                    .onDelete(perform: removeTempStep)
                    
                    HStack {
                        Image(systemName: "plus")
                            .foregroundStyle(Color.accentColor)
                        TextField("Adicionar sub-etapa...", text: $newStepTitle)
                            .onSubmit {
                                addTempStep()
                            }
                        if !newStepTitle.isEmpty {
                            Button("Adicionar", action: addTempStep)
                                .font(.caption)
                                .bold()
                        }
                    }
                }
                
                // PROJETO E SETOR
                Section(header: Text("Organização")) {
                    if !projects.isEmpty {
                        Picker("Projeto / Lista", selection: $selectedProject) {
                            Text("Caixa de Entrada (Nenhum)").tag(Project?.none)
                            ForEach(projects) { project in
                                Text("\(project.sector?.name ?? "") • \(project.name)").tag(Project?.some(project))
                            }
                        }
                    }
                    
                    Picker("Prioridade", selection: $priority) {
                        Text("Baixa").tag(Priority.low)
                        Text("Média").tag(Priority.medium)
                        Text("Alta").tag(Priority.high)
                    }
                    .pickerStyle(.segmented)
                }
                
                // BOTAO SALVAR
                Section {
                    Button(action: saveMission) {
                        Text("Adicionar Lembrete")
                            .frame(maxWidth: .infinity)
                            .bold()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Novo Lembrete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        speechManager.stopRecording()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Adicionar", action: saveMission)
                        .bold()
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onChange(of: speechManager.recognizedText) { _, newValue in
                if !newValue.isEmpty {
                    self.title = newValue
                }
            }
        }
    }
    
    private func addTempStep() {
        let trimmed = newStepTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        tempSteps.append(trimmed)
        newStepTitle = ""
    }
    
    private func removeTempStep(at offsets: IndexSet) {
        tempSteps.remove(atOffsets: offsets)
    }
    
    private func toggleSpeech() {
        if isListening {
            speechManager.stopRecording()
            isListening = false
        } else {
            speechManager.startRecording()
            isListening = true
        }
    }
    
    private func saveMission() {
        speechManager.stopRecording()
        let newMission = Mission(
            title: title,
            details: details,
            dueDate: hasDueDate ? dueDate : nil,
            estimatedMinutes: hasEstimatedTime ? estimatedMinutes : nil,
            priority: priority,
            recurrence: recurrence
        )
        newMission.project = selectedProject
        modelContext.insert(newMission)
        
        // Criar as sub-etapas vinculadas
        for (index, stepTitle) in tempSteps.enumerated() {
            let step = Step(title: stepTitle, order: index)
            step.mission = newMission
            modelContext.insert(step)
        }
        
        do {
            try modelContext.save()
            NotificationManager.shared.scheduleNotification(for: newMission)
            dismiss()
        } catch {
            print("Error saving mission: \(error)")
        }
    }
    
    private func nextWeekend() -> Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.weekday = 7 // Sábado
        return calendar.nextDate(after: Date(), matching: components, matchingPolicy: .nextTime) ?? Date()
    }
}
