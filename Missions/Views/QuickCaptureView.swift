import SwiftUI
import SwiftData
import UIKit

enum RecurrenceDuration: String, CaseIterable {
    case forever = "Para Sempre"
    case oneMonth = "Por 1 Mês"
    case twoMonths = "Por 2 Meses"
    case threeMonths = "Por 3 Meses"
    case customDate = "Data Específica"
}

struct QuickCaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \Project.name) var projects: [Project]
    
    @State private var title: String = ""
    @State private var details: String = ""
    @State private var priority: Priority = .medium
    @State private var recurrence: Recurrence = .none
    @State private var selectedDays: Set<Int> = [2, 4, 6] // Seg, Qua, Sex por padrão
    @State private var recurrenceDuration: RecurrenceDuration = .forever
    @State private var customEndDate: Date = Calendar.current.date(byAdding: .month, value: 2, to: Date()) ?? Date()
    @State private var estimatedMinutes: Int = 30
    @State private var hasEstimatedTime: Bool = false
    @State private var dueDate: Date = Date()
    @State private var hasDueDate: Bool = true
    @State private var includeTime: Bool = false
    @State private var isAlarmMode: Bool = false
    @State private var selectedProject: Project?
    
    // Checklist/Subtarefas diretamente na captura
    @State private var newStepTitle: String = ""
    @State private var tempSteps: [String] = []
    
    var body: some View {
        NavigationStack {
            Form {
                // TÍTULO DA MISSÃO
                Section(header: Text("Lembrete / Objetivo")) {
                    TextField("O que precisa ser feito?", text: $title)
                        .font(.headline)
                }
                
                // ANOTAÇÕES E DETALHES
                Section(header: Text("Anotações & Links")) {
                    TextField("Adicione detalhes, links ou observações...", text: $details, axis: .vertical)
                        .lineLimit(2...6)
                }
                
                // SELEÇÃO DE DATA E HORA
                Section(header: Text("Data e Hora")) {
                    Toggle("Agendar para uma data", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("Data", selection: $dueDate, displayedComponents: [.date])
                            .environment(\.locale, Locale(identifier: "pt_BR"))
                        
                        Toggle("Definir Horário Específico", isOn: $includeTime)
                        
                        if includeTime {
                            DatePicker("Horário", selection: $dueDate, displayedComponents: [.hourAndMinute])
                                .environment(\.locale, Locale(identifier: "pt_BR"))
                        }
                    }
                }
                
                // PRIORIDADE E RECORRÊNCIA
                Section(header: Text("Planejamento & Repetição")) {
                    Picker("Prioridade", selection: $priority) {
                        Text("Baixa").tag(Priority.low)
                        Text("Média").tag(Priority.medium)
                        Text("🔥 Alta").tag(Priority.high)
                    }
                    .pickerStyle(.segmented)
                    
                    Picker("Repetição", selection: $recurrence) {
                        ForEach(Recurrence.allCases, id: \.self) { rec in
                            Text(rec.rawValue).tag(rec)
                        }
                    }
                    
                    // DIAS DA SEMANA CUSTOMIZADOS (se escolher 'Dias da Semana')
                    if recurrence == .customDays {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Escolha os dias da semana:")
                                .font(.caption)
                                .bold()
                                .foregroundStyle(.secondary)
                            
                            HStack(spacing: 6) {
                                ForEach([
                                    (1, "Dom"), (2, "Seg"), (3, "Ter"), (4, "Qua"),
                                    (5, "Qui"), (6, "Sex"), (7, "Sáb")
                                ], id: \.0) { id, name in
                                    let isSelected = selectedDays.contains(id)
                                    Button(action: {
                                        if isSelected {
                                            selectedDays.remove(id)
                                        } else {
                                            selectedDays.insert(id)
                                        }
                                    }) {
                                        Text(name)
                                            .font(.caption2)
                                            .bold()
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                            .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.12))
                                            .foregroundStyle(isSelected ? .white : .primary)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // DURAÇÃO DA RECORRÊNCIA (ex: por 2 meses)
                    if recurrence != .none {
                        Picker("Duração da Repetição", selection: $recurrenceDuration) {
                            ForEach(RecurrenceDuration.allCases, id: \.self) { dur in
                                Text(dur.rawValue).tag(dur)
                            }
                        }
                        
                        if recurrenceDuration == .customDate {
                            DatePicker("Repetir Até", selection: $customEndDate, displayedComponents: [.date])
                                .environment(\.locale, Locale(identifier: "pt_BR"))
                        }
                    }
                    
                    Toggle("Definir Estimativa de Tempo", isOn: $hasEstimatedTime)
                    
                    if hasEstimatedTime {
                        Stepper("\(estimatedMinutes) minutos de foco", value: $estimatedMinutes, in: 5...240, step: 15)
                    }
                    
                    Toggle(isOn: $isAlarmMode) {
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
                
                // CHECKLIST / SUBTAREFAS
                Section(header: Text("Checklist (Subtarefas)")) {
                    ForEach(tempSteps.indices, id: \.self) { index in
                        HStack {
                            Image(systemName: "circle")
                                .foregroundStyle(.gray)
                            Text(tempSteps[index])
                            Spacer()
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                withAnimation {
                                    tempSteps.remove(at: index)
                                }
                            } label: {
                                Label("Excluir Etapa", systemImage: "trash")
                            }
                        }
                    }
                    .onDelete(perform: removeTempStep)
                    
                    HStack(alignment: .top) {
                        Image(systemName: "plus")
                            .foregroundStyle(Color.accentColor)
                            .padding(.top, 4)
                        
                        TextField("Adicionar sub-etapa ou colar lista...", text: $newStepTitle, axis: .vertical)
                            .lineLimit(1...5)
                            .onChange(of: newStepTitle) { newValue in
                                if newValue.contains("\n") {
                                    addTempStep()
                                }
                            }
                            .onSubmit {
                                addTempStep()
                            }
                        
                        if !newStepTitle.isEmpty {
                            Button("Adicionar", action: addTempStep)
                                .font(.caption)
                                .bold()
                        }
                    }
                    
                    Button(action: pasteClipboardTempSteps) {
                        HStack {
                            Image(systemName: "doc.on.clipboard.fill")
                                .foregroundStyle(Color.accentColor)
                            Text("Colar Lista Copiada como Várias Etapas")
                                .font(.subheadline)
                                .bold()
                                .foregroundStyle(Color.accentColor)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // PROJETO E SETOR
                Section(header: Text("Organização")) {
                    if !projects.isEmpty {
                        Picker("Projeto / Setor", selection: $selectedProject) {
                            Text("Nenhum (Caixa de Entrada)").tag(nil as Project?)
                            ForEach(projects) { project in
                                Text("\(project.sector?.name ?? "Setor") • \(project.name)")
                                    .tag(project as Project?)
                            }
                        }
                    }
                }
                
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
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Adicionar", action: saveMission)
                        .bold()
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .dismissKeyboardOnScroll()
        }
    }
    
    private func pasteClipboardTempSteps() {
        guard let clipboardString = UIPasteboard.general.string else { return }
        let lines = clipboardString.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        for line in lines {
            let cleanTitle = line.replacingOccurrences(of: #"^([\-\*\•]|\d+[\.\)])\s+"#, with: "", options: .regularExpression)
            guard !cleanTitle.isEmpty else { continue }
            tempSteps.append(cleanTitle)
        }
    }
    
    private func addTempStep() {
        let trimmed = newStepTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let lines = trimmed.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        for line in lines {
            let cleanTitle = line.replacingOccurrences(of: #"^([\-\*\•]|\d+[\.\)])\s+"#, with: "", options: .regularExpression)
            guard !cleanTitle.isEmpty else { continue }
            tempSteps.append(cleanTitle)
        }
        
        newStepTitle = ""
    }
    
    private func removeTempStep(at offsets: IndexSet) {
        tempSteps.remove(atOffsets: offsets)
    }
    
    private func calculatedEndDate() -> Date? {
        guard recurrence != .none else { return nil }
        let refDate = hasDueDate ? dueDate : Date()
        let calendar = Calendar.current
        switch recurrenceDuration {
        case .forever:
            return nil
        case .oneMonth:
            return calendar.date(byAdding: .month, value: 1, to: refDate)
        case .twoMonths:
            return calendar.date(byAdding: .month, value: 2, to: refDate)
        case .threeMonths:
            return calendar.date(byAdding: .month, value: 3, to: refDate)
        case .customDate:
            return customEndDate
        }
    }
    
    private func saveMission() {
        let newMission = Mission(
            title: title,
            details: details,
            dueDate: hasDueDate ? dueDate : nil,
            estimatedMinutes: hasEstimatedTime ? estimatedMinutes : nil,
            priority: priority,
            recurrence: recurrence,
            selectedDays: Array(selectedDays),
            recurrenceEndDate: calculatedEndDate(),
            isAlarmMode: isAlarmMode
        )
        newMission.project = selectedProject
        modelContext.insert(newMission)
        
        // Criar as sub-etapas vinculadas
        for (index, stepTitle) in tempSteps.enumerated() {
            let step = Step(title: stepTitle, order: index)
            step.mission = newMission
            modelContext.insert(step)
        }
        
        try? modelContext.save()
        NotificationManager.shared.scheduleNotification(for: newMission)
        dismiss()
    }
}
