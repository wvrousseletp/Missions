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
    
    var initialProject: Project?
    
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
    @State private var isWaitingFor: Bool = false
    @State private var waitingPerson: String = ""
    @State private var selectedProject: Project?
    
    init(initialProject: Project? = nil) {
        self.initialProject = initialProject
        _selectedProject = State(initialValue: initialProject)
    }
    
    @FocusState private var isTitleFocused: Bool
    
    // Checklist/Subtarefas diretamente na captura
    @State private var newStepTitle: String = ""
    @State private var tempSteps: [String] = []
    
    @Query(sort: \CustomTaskTemplate.createdAt, order: .reverse) var customTaskTemplates: [CustomTaskTemplate]
    @State private var showingTaskTemplatePicker = false
    
    var body: some View {
        NavigationStack {
            Form {
                // TÍTULO DA MISSÃO E SELETOR DE TEMPLATE
                Section(header: Text("Lembrete / Objetivo")) {
                    TextField("O que precisa ser feito?", text: $title)
                        .font(.headline)
                        .focused($isTitleFocused)
                    
                    Button(action: { showingTaskTemplatePicker = true }) {
                        HStack {
                            Image(systemName: "wand.and.stars")
                                .foregroundStyle(Color.accentColor)
                            Text("Usar Padrão de Tarefa (Checklist Pronto)")
                                .font(.subheadline)
                                .bold()
                                .foregroundStyle(Color.accentColor)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
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
                    
                    Toggle(isOn: $isWaitingFor) {
                        HStack {
                            Image(systemName: "hourglass.badge.plus")
                                .foregroundStyle(.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Aguardando Terceiro")
                                    .bold()
                                Text("Depende de outra pessoa para concluir")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    if isWaitingFor {
                        TextField("Quem você está aguardando? (ex: Deise, Fornecedor)", text: $waitingPerson)
                            .font(.subheadline)
                    }
                }
                
                // CHECKLIST / SUBTAREFAS
                Section(header: Text("Checklist (Subtarefas)")) {
                    ForEach(Array(tempSteps.enumerated()), id: \.offset) { index, stepTitle in
                        HStack {
                            Image(systemName: "circle")
                                .foregroundStyle(.gray)
                            Text(stepTitle)
                            Spacer()
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                withAnimation {
                                    if index < tempSteps.count {
                                        tempSteps.remove(at: index)
                                    }
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
            .navigationBarItems(
                leading: Button("Cancelar") {
                    dismiss()
                },
                trailing: Button("Adicionar", action: saveMission)
                    .bold()
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
            .dismissKeyboardOnScroll()
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    isTitleFocused = true
                }
            }
            .sheet(isPresented: $showingTaskTemplatePicker) {
                TaskTemplateSelectionSheet(
                    customTemplates: customTaskTemplates,
                    onSelect: { selectedTitle, selectedDetails, selectedMins, selectedSteps in
                        title = selectedTitle
                        details = selectedDetails
                        estimatedMinutes = selectedMins
                        hasEstimatedTime = selectedMins > 0
                        tempSteps = selectedSteps
                        showingTaskTemplatePicker = false
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }
                )
            }
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
            isAlarmMode: isAlarmMode,
            isWaitingFor: isWaitingFor,
            waitingPerson: waitingPerson
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

struct TaskTemplateSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    var customTemplates: [CustomTaskTemplate]
    var onSelect: (String, String, Int, [String]) -> Void
    
    @State private var showingManager = false
    
    let defaultTaskTemplates: [(title: String, icon: String, category: String, details: String, mins: Int, steps: [String])] = [
        (
            title: "Ir para Retiro / Evento Espiritual",
            icon: "cross.fill",
            category: "Espiritual",
            details: "Checklist completo de bagagem, estudo e transporte.",
            mins: 45,
            steps: [
                "Arrumar mala com roupas confortáveis",
                "Separar Bíblia, bloco de notas e caneta",
                "Kit de higiene pessoal e toalha",
                "Confirmar horário e ponto da carona/ônibus",
                "Baixar playlist e louvores offline"
            ]
        ),
        (
            title: "Viagem a Trabalho / Evento",
            icon: "briefcase.fill",
            category: "Trabalho",
            details: "Checklist de passagens, documentos e materiais de trabalho.",
            mins: 60,
            steps: [
                "Conferir passagens aéreas e reserva de hotel",
                "Mala com roupas sociais/esporte fino",
                "Carregador de celular, notebook e adaptadores",
                "Revisar arquivos da apresentação offline",
                "Cartões de visita e documento de identificação"
            ]
        ),
        (
            title: "Checklist para Viagem de Carro",
            icon: "car.side.fill",
            category: "Viagem",
            details: "Inspeção preventiva para pegar a estrada com segurança.",
            mins: 30,
            steps: [
                "Calibrar 4 pneus e checar pressão do estepe",
                "Conferir óleo do motor e fluido do radiador",
                "Verificar saldo da tag de pedágio",
                "Separar kit de água e lanches rápidos",
                "Configurar GPS e rotas no celular"
            ]
        ),
        (
            title: "Preparação para Reunião Importante",
            icon: "person.3.fill",
            category: "Trabalho",
            details: "Pauta, equipamentos e alinhamento prévio.",
            mins: 20,
            steps: [
                "Definir pauta com 3 tópicos prioritários",
                "Testar microfone, câmera e link da chamada",
                "Separar dados e relatórios necessários",
                "Enviar lembrete para os participantes"
            ]
        )
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // SEÇÃO 1: TEMPLATES PERSONALIZADOS DO USUÁRIO
                    if !customTemplates.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("⭐ Seus Padrões Personalizados")
                                .font(.headline)
                                .bold()
                                .padding(.horizontal)
                            
                            ForEach(customTemplates) { template in
                                Button(action: {
                                    onSelect(template.title, template.details, template.estimatedMinutes, template.steps)
                                }) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text(template.title)
                                                .font(.headline)
                                                .bold()
                                                .foregroundStyle(.primary)
                                            Spacer()
                                            Text("\(template.steps.count) passos")
                                                .font(.caption2)
                                                .bold()
                                                .foregroundStyle(Color.accentColor)
                                        }
                                        
                                        if !template.details.isEmpty {
                                            Text(template.details)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(2)
                                        }
                                    }
                                    .padding(14)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.accentColor.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // SEÇÃO 2: PADRÕES PRONTOS DO APP
                    VStack(alignment: .leading, spacing: 12) {
                        Text("✨ Padrões Prontos Recomendados")
                            .font(.headline)
                            .bold()
                            .padding(.horizontal)
                        
                        ForEach(defaultTaskTemplates, id: \.title) { t in
                            Button(action: {
                                onSelect(t.title, t.details, t.mins, t.steps)
                            }) {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(spacing: 10) {
                                        Image(systemName: t.icon)
                                            .font(.title3)
                                            .foregroundStyle(Color.accentColor)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(t.title)
                                                .font(.headline)
                                                .bold()
                                                .foregroundStyle(.primary)
                                            
                                            Text(t.details)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                    }
                                    
                                    Divider()
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        ForEach(t.steps, id: \.self) { step in
                                            HStack(spacing: 6) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.caption2)
                                                    .foregroundStyle(.green)
                                                Text(step)
                                                    .font(.caption)
                                                    .foregroundStyle(.primary)
                                            }
                                        }
                                    }
                                }
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.secondary.opacity(0.07))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Escolha um Padrão de Tarefa")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingManager = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "gearshape.fill")
                            Text("Gerenciar")
                        }
                        .font(.caption)
                        .bold()
                    }
                }
            }
            .sheet(isPresented: $showingManager) {
                TemplateManagerView()
            }
        }
    }
}

