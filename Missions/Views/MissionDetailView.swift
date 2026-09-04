import SwiftUI
import SwiftData
import UIKit

struct MissionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var mission: Mission
    
    @State private var newStepTitle: String = ""
    @State private var showingDeleteAlert: Bool = false
    @State private var showingImageScanner: Bool = false
    
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
                
                // CAMPO DE ADICIONAR OU COLAR MULTILINHAS
                HStack(alignment: .top) {
                    Image(systemName: "plus")
                        .foregroundColor(.accentColor)
                        .padding(.top, 4)
                    
                    TextField("Adicionar etapa ou colar lista...", text: $newStepTitle, axis: .vertical)
                        .lineLimit(1...5)
                        .onChange(of: newStepTitle) { newValue in
                            if newValue.contains("\n") {
                                addStep()
                            }
                        }
                        .onSubmit {
                            addStep()
                        }
                    
                    if !newStepTitle.isEmpty {
                        Button("Adicionar", action: addStep)
                            .font(.caption)
                            .bold()
                    }
                }
                
                // BOTÃO DE ATALHO PARA COLAR ÁREA DE TRANSFERÊNCIA
                Button(action: pasteClipboardSteps) {
                    HStack {
                        Image(systemName: "doc.on.clipboard.fill")
                            .foregroundStyle(Color.accentColor)
                        Text("Colar Lista Copiada como Várias Etapas")
                            .font(.subheadline)
                            .bold()
                            .foregroundStyle(Color.accentColor)
                    }
                    .padding(.vertical, 2)
                }
                
                // BOTÃO PARA ESCANEAR LISTA POR FOTO (OCR)
                Button(action: { showingImageScanner = true }) {
                    HStack {
                        Image(systemName: "camera.viewfinder")
                            .foregroundStyle(.blue)
                        Text("Escanear Lista por Foto / Imagem")
                            .font(.subheadline)
                            .bold()
                            .foregroundStyle(.blue)
                    }
                    .padding(.vertical, 2)
                }
                
                // BOTÃO DE LEITOR VIVA-VOZ NO CARRO
                Button(action: {
                    AudioSummaryManager.shared.speakRoute(for: mission)
                }) {
                    HStack {
                        Image(systemName: AudioSummaryManager.shared.isSpeaking ? "speaker.wave.3.fill" : "car.fill")
                            .foregroundStyle(.orange)
                        Text(AudioSummaryManager.shared.isSpeaking ? "Parar Leitura Viva-Voz" : "🚗 Modo Viva-Voz (Ouvir Rota)")
                            .font(.subheadline)
                            .bold()
                            .foregroundStyle(.orange)
                    }
                    .padding(.vertical, 2)
                }
                
                // BADGE DE ORÇAMENTO TOTAL ESTIMADO DE COMPRAS
                if mission.totalEstimatedCost > 0 {
                    HStack {
                        Image(systemName: "banknote.fill")
                            .foregroundStyle(.green)
                        Text("Orçamento Estimado: R$ \(mission.totalEstimatedCost, specifier: "%.2f")")
                            .font(.subheadline)
                            .bold()
                            .foregroundStyle(.green)
                    }
                    .padding(.vertical, 4)
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
                
                Toggle(isOn: $mission.isWaitingFor) {
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
                
                if mission.isWaitingFor {
                    TextField("Quem você está aguardando? (ex: Deise, Fornecedor)", text: $mission.waitingPerson)
                        .font(.subheadline)
                }
                
                Button(action: {
                    withAnimation {
                        DynamicIslandManager.shared.togglePin(for: mission)
                    }
                }) {
                    HStack {
                        Image(systemName: DynamicIslandManager.shared.isPinned(mission) ? "pin.slash.fill" : "pin.fill")
                            .foregroundStyle(.purple)
                        Text(DynamicIslandManager.shared.isPinned(mission) ? "Desafixar da Dynamic Island" : "Fixar na Dynamic Island")
                            .bold()
                            .foregroundStyle(.purple)
                    }
                    .padding(.vertical, 4)
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
        .sheet(isPresented: $showingImageScanner) {
            ImageScannerView { extractedLines in
                var currentStepsCount = mission.steps?.count ?? 0
                for line in extractedLines {
                    let step = Step(title: line, order: currentStepsCount)
                    step.mission = mission
                    modelContext.insert(step)
                    currentStepsCount += 1
                }
                try? modelContext.save()
            }
        }
        .dismissKeyboardOnScroll()
    }
    
    private func deleteMission() {
        NotificationManager.shared.cancelNotification(for: mission)
        modelContext.delete(mission)
        try? modelContext.save()
        dismiss()
    }
    
    private func pasteClipboardSteps() {
        guard let clipboardString = UIPasteboard.general.string else { return }
        let lines = clipboardString.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        var currentStepsCount = mission.steps?.count ?? 0
        for line in lines {
            let cleanTitle = line.replacingOccurrences(of: #"^([\-\*\•]|\d+[\.\)])\s+"#, with: "", options: .regularExpression)
            guard !cleanTitle.isEmpty else { continue }
            
            let step = Step(title: cleanTitle, order: currentStepsCount)
            step.mission = mission
            modelContext.insert(step)
            currentStepsCount += 1
        }
        try? modelContext.save()
    }
    
    private func addStep() {
        let trimmed = newStepTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let lines = trimmed.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        var currentStepsCount = mission.steps?.count ?? 0
        for line in lines {
            let cleanTitle = line.replacingOccurrences(of: #"^([\-\*\•]|\d+[\.\)])\s+"#, with: "", options: .regularExpression)
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
