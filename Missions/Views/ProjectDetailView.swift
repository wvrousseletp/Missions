import SwiftUI
import SwiftData
import UIKit

struct ProjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var project: Project
    
    @State private var viewMode: Int = 0 // 0: Lista, 1: Pipeline, 2: Fases
    @State private var showingDeleteAlert = false
    @State private var showingAddOptions = false
    @State private var showingQuickCapture = false
    @State private var showingTemplates = false
    @State private var showingImageScanner = false
    @State private var showingProjectBrainDump = false
    @State private var projectDumpText: String = ""
    
    var allMissions: [Mission] {
        project.missions?.sorted(by: { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) }) ?? []
    }
    
    var completedMissions: [Mission] {
        allMissions.filter { $0.isCompleted }
    }
    
    var pendingMissions: [Mission] {
        allMissions.filter { !$0.isCompleted && !$0.isWaitingFor }
    }
    
    var waitingMissions: [Mission] {
        allMissions.filter { !$0.isCompleted && $0.isWaitingFor }
    }
    
    var totalEstimatedCost: Double {
        allMissions.reduce(0) { $0 + $1.totalEstimatedCost }
    }
    
    var deadlineInfo: (text: String, color: Color, icon: String)? {
        guard let target = project.targetDate else { return nil }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let targetDay = calendar.startOfDay(for: target)
        
        let components = calendar.dateComponents([.day], from: today, to: targetDay)
        guard let days = components.day else { return nil }
        
        if days < 0 {
            return ("Atrasado por \(abs(days)) dias", .red, "exclamationmark.triangle.fill")
        } else if days == 0 {
            return ("Vence Hoje!", .orange, "clock.badge.exclamationmark.fill")
        } else if days <= 7 {
            return ("Faltam \(days) dias", .orange, "hourglass")
        } else {
            return ("Faltam \(days) dias", .blue, "calendar")
        }
    }
    
    var phasesDictionary: [String: [Mission]] {
        Dictionary(grouping: allMissions) { m in
            m.phase.isEmpty ? "Sem Fase Definida" : m.phase
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
                // SELETOR DE MODO DE VISUALIZAÇÃO
                Picker("Visualização", selection: $viewMode) {
                    Text("📋 Lista").tag(0)
                    Text("📊 Pipeline").tag(1)
                    Text("🚩 Fases").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 6)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // 1. CABEÇALHO INTELIGENTE DO PROJETO (PROGRESSO, PRAZO & ORÇAMENTO)
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top, spacing: 12) {
                                Circle()
                                    .fill(Color(hex: project.colorHex ?? "") ?? Color.accentColor)
                                    .frame(width: 14, height: 14)
                                    .padding(.top, 4)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    if let sector = project.sector {
                                        HStack(spacing: 4) {
                                            Image(systemName: sector.iconName)
                                                .font(.caption2)
                                            Text(sector.name)
                                                .font(.caption2)
                                                .bold()
                                        }
                                        .foregroundStyle(Color(hex: sector.colorHex) ?? Color.accentColor)
                                    }
                                    
                                    if !project.projectDescription.isEmpty {
                                        Text(project.projectDescription)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Text("\(Int(project.progress * 100))%")
                                    .font(.title2)
                                    .bold()
                                    .foregroundStyle(Color(hex: project.colorHex ?? "") ?? Color.accentColor)
                            }
                            
                            ProgressView(value: project.progress)
                                .tint(Color(hex: project.colorHex ?? "") ?? Color.accentColor)
                            
                            // BADGES DE PRAZO E ORÇAMENTO ESTIMADO DO PROJETO
                            HStack(spacing: 8) {
                                if let deadline = deadlineInfo {
                                    HStack(spacing: 4) {
                                        Image(systemName: deadline.icon)
                                            .font(.caption2)
                                        Text(deadline.text)
                                            .font(.caption2)
                                            .bold()
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(deadline.color.opacity(0.15))
                                    .foregroundStyle(deadline.color)
                                    .clipShape(Capsule())
                                }
                                
                                if totalEstimatedCost > 0 {
                                    HStack(spacing: 4) {
                                        Image(systemName: "banknote.fill")
                                            .font(.caption2)
                                        Text("Total: R$ \(totalEstimatedCost, specifier: "%.2f")")
                                            .font(.caption2)
                                            .bold()
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green.opacity(0.15))
                                    .foregroundStyle(.green)
                                    .clipShape(Capsule())
                                }
                                
                                Spacer()
                                
                                Button(action: { showingTemplates = true }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "wand.and.stars")
                                            .font(.caption2)
                                        Text("Templates Prontos")
                                            .font(.caption2)
                                            .bold()
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.purple.opacity(0.15))
                                    .foregroundStyle(.purple)
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(14)
                        .background(Color.secondary.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        // 2. CONTEÚDO BASEADO NO MODO SELECIONADO
                        if allMissions.isEmpty {
                            // ESTADO VAZIO COM ATALHOS DE ALTA PRODUTIVIDADE
                            VStack(spacing: 16) {
                                Image(systemName: "folder.badge.gearshape")
                                    .font(.system(size: 48))
                                    .foregroundStyle(Color(hex: project.colorHex ?? "")?.opacity(0.6) ?? Color.accentColor.opacity(0.6))
                                
                                Text("Nenhuma missão neste projeto ainda")
                                    .font(.headline)
                                    .bold()
                                
                                Text("Escolha uma forma rápida de alimentar este projeto sem esforço mental:")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                                
                                VStack(spacing: 10) {
                                    // 🪄 USAR TEMPLATE PRONTO
                                    Button(action: { showingTemplates = true }) {
                                        HStack {
                                            Image(systemName: "wand.and.stars")
                                                .font(.title3)
                                                .foregroundStyle(.purple)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Usar Modelo Operacional Pronto")
                                                    .font(.headline)
                                                    .bold()
                                                Text("Injetar missões pré-configuradas (Viagem, Reforma, Vendas...)")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding(12)
                                        .background(Color.purple.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                    .buttonStyle(.plain)
                                    
                                    // 🧠 DESCARREGO MENTAL DO PROJETO
                                    Button(action: { showingProjectBrainDump = true }) {
                                        HStack {
                                            Image(systemName: "brain.head.profile")
                                                .font(.title3)
                                                .foregroundStyle(.blue)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Descarrego Mental neste Projeto")
                                                    .font(.headline)
                                                    .bold()
                                                Text("Digite várias linhas livres para converter em missões")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding(12)
                                        .background(Color.blue.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                    .buttonStyle(.plain)
                                    
                                    // 📋 COLAR LISTA COPIADA
                                    Button(action: pasteClipboardMissions) {
                                        HStack {
                                            Image(systemName: "doc.on.clipboard.fill")
                                                .font(.title3)
                                                .foregroundStyle(.orange)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Colar Lista Copiada do WhatsApp/Notas")
                                                    .font(.headline)
                                                    .bold()
                                                Text("Converte texto copiado em missões individuais")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding(12)
                                        .background(Color.orange.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                    .buttonStyle(.plain)
                                    
                                    // 📷 ESCANEAR FOTO / DOCUMENTO
                                    Button(action: { showingImageScanner = true }) {
                                        HStack {
                                            Image(systemName: "camera.viewfinder")
                                                .font(.title3)
                                                .foregroundStyle(.green)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Escanear Lista por Foto / OCR")
                                                    .font(.headline)
                                                    .bold()
                                                Text("Extrai missões de orçamentos e papéis")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding(12)
                                        .background(Color.green.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.top, 16)
                        } else {
                            // CONTEÚDO COM MISSÕES EXISTENTES
                            if viewMode == 0 {
                                // 📋 VISÃO EM LISTA COMPLETA
                                VStack(alignment: .leading, spacing: 12) {
                                    ForEach(allMissions) { mission in
                                        MissionCard(mission: mission)
                                    }
                                }
                            } else if viewMode == 1 {
                                // 📊 VISÃO DE PIPELINE (STATUS)
                                VStack(alignment: .leading, spacing: 16) {
                                    if !pendingMissions.isEmpty {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("📝 A Fazer / Pendentes (\(pendingMissions.count))")
                                                .font(.headline)
                                                .foregroundStyle(.blue)
                                            ForEach(pendingMissions) { mission in
                                                MissionCard(mission: mission)
                                            }
                                        }
                                    }
                                    
                                    if !waitingMissions.isEmpty {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("⏳ Aguardando Terceiro (\(waitingMissions.count))")
                                                .font(.headline)
                                                .foregroundStyle(.orange)
                                            ForEach(waitingMissions) { mission in
                                                MissionCard(mission: mission)
                                            }
                                        }
                                    }
                                    
                                    if !completedMissions.isEmpty {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("✅ Concluídas (\(completedMissions.count))")
                                                .font(.headline)
                                                .foregroundStyle(.green)
                                            ForEach(completedMissions) { mission in
                                                MissionCard(mission: mission)
                                            }
                                        }
                                    }
                                }
                            } else if viewMode == 2 {
                                // 🚩 VISÃO DE FASES / MARCOS (MILESTONES)
                                VStack(alignment: .leading, spacing: 16) {
                                    ForEach(Array(phasesDictionary.keys.sorted()), id: \.self) { phaseName in
                                        if let phaseMissions = phasesDictionary[phaseName], !phaseMissions.isEmpty {
                                            VStack(alignment: .leading, spacing: 8) {
                                                HStack {
                                                    Image(systemName: "flag.fill")
                                                        .foregroundStyle(Color(hex: project.colorHex ?? "") ?? Color.accentColor)
                                                    Text(phaseName)
                                                        .font(.headline)
                                                        .bold()
                                                    Spacer()
                                                    Text("\(phaseMissions.filter { $0.isCompleted }.count)/\(phaseMissions.count)")
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                }
                                                .padding(.horizontal, 4)
                                                
                                                ForEach(phaseMissions) { mission in
                                                    MissionCard(mission: mission)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 90)
                }
            }
        .onAppear {
            FABManager.shared.customAction = {
                showingAddOptions = true
            }
        }
        .onDisappear {
            FABManager.shared.customAction = nil
        }
        .confirmationDialog("Adicionar no Projeto \(project.name)", isPresented: $showingAddOptions, titleVisibility: .visible) {
            Button("🎯 Nova Missão / Tarefa") {
                showingQuickCapture = true
            }
            
            Button("🧠 Descarrego Mental") {
                showingProjectBrainDump = true
            }
            
            Button("📋 Colar Lista Copiada") {
                pasteClipboardMissions()
            }
            
            Button("🪄 Injetar Modelo de Projeto") {
                showingTemplates = true
            }
            
            Button("📷 Escanear por Foto / OCR") {
                showingImageScanner = true
            }
            
            Button("Cancelar", role: .cancel) { }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(action: { showingTemplates = true }) {
                        Label("Templates Prontos", systemImage: "wand.and.stars")
                    }
                    Button(action: { showingProjectBrainDump = true }) {
                        Label("Descarrego Mental no Projeto", systemImage: "brain.head.profile")
                    }
                    Button(action: pasteClipboardMissions) {
                        Label("Colar Lista Copiada", systemImage: "doc.on.clipboard")
                    }
                    Button(action: { showingImageScanner = true }) {
                        Label("Escanear por Foto / OCR", systemImage: "camera.viewfinder")
                    }
                    Divider()
                    Button(role: .destructive, action: { showingDeleteAlert = true }) {
                        Label("Excluir Projeto", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
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
        .sheet(isPresented: $showingTemplates) {
            TemplatePickerView(project: project)
        }
        .sheet(isPresented: $showingImageScanner) {
            ImageScannerView { extractedLines in
                for line in extractedLines {
                    let m = Mission(title: line)
                    m.project = project
                    modelContext.insert(m)
                }
                try? modelContext.save()
            }
        }
        .alert("Descarrego Mental no Projeto 🧠", isPresented: $showingProjectBrainDump) {
            TextField("Digite 1 missão por linha...", text: $projectDumpText, axis: .vertical)
            Button("Salvar Missões") {
                processProjectBrainDump()
            }
            Button("Cancelar", role: .cancel) { }
        } message: {
            Text("Digite ou cole várias ideias de missões para este projeto (uma por linha):")
        }
    }
    
    private func pasteClipboardMissions() {
        guard let clipboardString = UIPasteboard.general.string else { return }
        let lines = clipboardString.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        for line in lines {
            let cleanTitle = line.replacingOccurrences(of: #"^([\-\*\•]|\d+[\.\)])\s+"#, with: "", options: .regularExpression)
            guard !cleanTitle.isEmpty else { continue }
            
            let m = Mission(title: cleanTitle)
            m.project = project
            modelContext.insert(m)
        }
        try? modelContext.save()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    private func processProjectBrainDump() {
        let lines = projectDumpText.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        guard !lines.isEmpty else { return }
        
        for line in lines {
            let cleanTitle = line.replacingOccurrences(of: #"^([\-\*\•]|\d+[\.\)])\s+"#, with: "", options: .regularExpression)
            guard !cleanTitle.isEmpty else { continue }
            
            let m = Mission(title: cleanTitle)
            m.project = project
            modelContext.insert(m)
        }
        
        try? modelContext.save()
        projectDumpText = ""
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    private func deleteProject() {
        modelContext.delete(project)
        try? modelContext.save()
        dismiss()
    }
}
