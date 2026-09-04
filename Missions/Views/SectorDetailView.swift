import SwiftUI
import SwiftData

struct SectorDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var sector: Sector
    
    @State private var selectedTab: Int = 0 // 0: Status List, 1: Timeline
    @State private var showingAddProject = false
    @State private var showingDeleteAlert = false
    @State private var showingEditGoal = false
    @State private var newGoalText = ""
    
    // Todas as missões vinculadas aos projetos deste setor
    var allMissionsInSector: [Mission] {
        guard let projects = sector.projects else { return [] }
        return projects.compactMap { $0.missions }.flatMap { $0 }
    }
    
    var completedMissionsCount: Int {
        allMissionsInSector.filter { $0.isCompleted }.count
    }
    
    var totalMissionsCount: Int {
        allMissionsInSector.count
    }
    
    var globalSectorProgress: Double {
        totalMissionsCount > 0 ? Double(completedMissionsCount) / Double(totalMissionsCount) : 0.0
    }
    
    // Avaliação de Saúde do Setor
    var sectorHealth: (status: String, color: Color, icon: String) {
        let pendingMissions = allMissionsInSector.filter { !$0.isCompleted }
        let now = Date()
        
        let overdueCount = pendingMissions.filter { m in
            guard let due = m.dueDate else { return false }
            return due < Calendar.current.startOfDay(for: now)
        }.count
        
        let dueTodayCount = pendingMissions.filter { m in
            guard let due = m.dueDate else { return false }
            return Calendar.current.isDateInToday(due)
        }.count
        
        if overdueCount > 0 {
            return ("Atrasado (\(overdueCount))", .red, "exclamationmark.triangle.fill")
        } else if dueTodayCount > 0 {
            return ("Atenção (Vence Hoje)", .orange, "clock.badge.exclamationmark.fill")
        } else {
            return ("Em Dia 🟢", .green, "checkmark.seal.fill")
        }
    }
    
    var starredProjects: [Project] {
        (sector.projects ?? []).filter { $0.isStarred }
    }
    
    var activeProjects: [Project] {
        (sector.projects ?? []).filter { $0.status == .active }
    }
    
    var pausedProjects: [Project] {
        (sector.projects ?? []).filter { $0.status == .paused }
    }
    
    var completedProjects: [Project] {
        (sector.projects ?? []).filter { $0.status == .completed }
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                // SEGMENTED PICKER DA VISÃO (STATUS vs CRONOGRAMA)
                Picker("Visualização", selection: $selectedTab) {
                    Text("🗂️ Status & Lista").tag(0)
                    Text("📅 Cronograma & Prazos").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 4)
                
                if selectedTab == 0 {
                    List {
                        // 1. DASHBOARD DE SAÚDE E PROGRESSO GLOBAL DO SETOR
                        Section {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack(alignment: .center, spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: sector.colorHex)?.opacity(0.2) ?? Color.accentColor.opacity(0.2))
                                            .frame(width: 52, height: 52)
                                        Image(systemName: sector.iconName)
                                            .font(.title2)
                                            .foregroundStyle(Color(hex: sector.colorHex) ?? .accentColor)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(sector.name)
                                            .font(.title2)
                                            .bold()
                                        
                                        HStack(spacing: 8) {
                                            Text(sectorHealth.status)
                                                .font(.caption)
                                                .bold()
                                                .foregroundStyle(sectorHealth.color)
                                            
                                            Text("•")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            
                                            Text("\(activeProjects.count) ativos")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                
                                // BARRA DE PROGRESSO GLOBAL DO SETOR
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("Progresso Geral do Setor")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text("\(Int(globalSectorProgress * 100))%")
                                            .font(.caption)
                                            .bold()
                                            .foregroundStyle(Color(hex: sector.colorHex) ?? Color.accentColor)
                                    }
                                    
                                    ProgressView(value: globalSectorProgress)
                                        .tint(Color(hex: sector.colorHex) ?? Color.accentColor)
                                }
                                
                                // META/OBJETIVO ESTRATÉGICO DO SETOR
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("🎯 META DO SETOR")
                                            .font(.caption2)
                                            .bold()
                                            .foregroundStyle(.secondary)
                                        
                                        Text((sector.targetGoal?.isEmpty ?? true) ? "Nenhuma meta cadastrada. Toque para definir." : sector.targetGoal ?? "")
                                            .font(.subheadline)
                                            .italic((sector.targetGoal?.isEmpty ?? true))
                                            .foregroundStyle((sector.targetGoal?.isEmpty ?? true) ? .secondary : .primary)
                                    }
                                    Spacer()
                                    Image(systemName: "pencil.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(Color(hex: sector.colorHex) ?? Color.accentColor)
                                }
                                .padding(10)
                                .background(Color.secondary.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .onTapGesture {
                                    newGoalText = sector.targetGoal ?? ""
                                    showingEditGoal = true
                                }
                            }
                            .padding(.vertical, 6)
                        }
                        
                        // 2. PROJETOS EM DESTAQUE (STARRED)
                        if !starredProjects.isEmpty {
                            Section(header: Text("⭐ Projetos em Destaque")) {
                                ForEach(starredProjects) { project in
                                    ProjectRowView(project: project, onDuplicate: { duplicateProject(project) })
                                }
                            }
                        }
                        
                        // 3. SEÇÃO 🚀 EM ANDAMENTO (ATIVOS)
                        Section(header: Text("🚀 Em Andamento (\(activeProjects.count))")) {
                            if activeProjects.isEmpty {
                                Text("Nenhum projeto ativo.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(activeProjects) { project in
                                    ProjectRowView(project: project, onDuplicate: { duplicateProject(project) })
                                }
                            }
                        }
                        
                        // 4. SEÇÃO ⏸️ EM PAUSA / ESPERA
                        if !pausedProjects.isEmpty {
                            Section(header: Text("⏸️ Em Pausa (\(pausedProjects.count))")) {
                                ForEach(pausedProjects) { project in
                                    ProjectRowView(project: project, onDuplicate: { duplicateProject(project) })
                                }
                            }
                        }
                        
                        // 5. SEÇÃO ✅ CONCLUÍDOS (ARQUIVADOS)
                        if !completedProjects.isEmpty {
                            Section(header: Text("✅ Concluídos (\(completedProjects.count))")) {
                                ForEach(completedProjects) { project in
                                    ProjectRowView(project: project, onDuplicate: { duplicateProject(project) })
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                } else {
                    // 📅 VISÃO DE CRONOGRAMA & LINHA DO TEMPO DOS PROJETOS
                    ProjectTimelineView(projects: sector.projects ?? [])
                }
            }
            
            // BOTÃO FLUTUANTE `+` NO CANTO INFERIOR DIREITO PARA CRIAR NOVO PROJETO
            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                showingAddProject = true
            }) {
                Image(systemName: "plus")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: sector.colorHex) ?? Color.accentColor, (Color(hex: sector.colorHex) ?? Color.accentColor).opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: (Color(hex: sector.colorHex) ?? Color.accentColor).opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
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
        .alert("Meta do Setor", isPresented: $showingEditGoal) {
            TextField("Ex: Concluir 5 entregas este mês", text: $newGoalText)
            Button("Cancelar", role: .cancel) { }
            Button("Salvar") {
                sector.targetGoal = newGoalText
                try? modelContext.save()
            }
        } message: {
            Text("Defina uma meta ou objetivo estratégico para o setor \(sector.name):")
        }
    }
    
    private func deleteSector() {
        modelContext.delete(sector)
        try? modelContext.save()
        dismiss()
    }
    
    // 📋 DUPLICAR PROJETO + TODAS AS MISSÕES E CHECKLISTS ASSOCIADOS
    private func duplicateProject(_ original: Project) {
        let duplicatedProject = Project(
            name: "\(original.name) (Cópia)",
            projectDescription: original.projectDescription,
            status: original.status,
            colorHex: original.colorHex,
            targetDate: original.targetDate
        )
        duplicatedProject.sector = sector
        modelContext.insert(duplicatedProject)
        
        // Copiar todas as missões
        if let originalMissions = original.missions {
            for m in originalMissions {
                let dupMission = Mission(
                    title: m.title,
                    details: m.details,
                    dueDate: m.dueDate,
                    estimatedMinutes: m.estimatedMinutes,
                    priority: m.priority,
                    recurrence: m.recurrence,
                    selectedDays: m.selectedDays,
                    recurrenceEndDate: m.recurrenceEndDate,
                    isAlarmMode: m.isAlarmMode
                )
                dupMission.project = duplicatedProject
                modelContext.insert(dupMission)
                
                // Copiar os passos/checklists da missão
                if let steps = m.steps {
                    for s in steps {
                        let dupStep = Step(title: s.title, isCompleted: s.isCompleted, order: s.order)
                        dupStep.mission = dupMission
                        modelContext.insert(dupStep)
                    }
                }
            }
        }
        
        try? modelContext.save()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

// ROW DE PROJETO COM BARRA DE PROGRESSO & AÇÕES RÁPIDAS
struct ProjectRowView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var project: Project
    var onDuplicate: () -> Void
    
    var body: some View {
        NavigationLink(destination: ProjectDetailView(project: project)) {
            HStack(spacing: 12) {
                // INDICADOR DE COR DO PROJETO
                Circle()
                    .fill(Color(hex: project.colorHex ?? "") ?? Color.accentColor)
                    .frame(width: 10, height: 10)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(project.name)
                            .font(.headline)
                        
                        if project.isStarred {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                        }
                        
                        Spacer()
                        
                        Text("\(Int(project.progress * 100))%")
                            .font(.caption)
                            .bold()
                            .foregroundStyle(.secondary)
                    }
                    
                    if !project.projectDescription.isEmpty {
                        Text(project.projectDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    
                    // BARRA DE PROGRESSO DO PROJETO
                    ProgressView(value: project.progress)
                        .tint(Color(hex: project.colorHex ?? "") ?? Color.accentColor)
                    
                    if let target = project.targetDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption2)
                            Text("Prazo: \(target.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .contextMenu {
            Button(action: {
                withAnimation {
                    project.isStarred.toggle()
                    try? modelContext.save()
                }
            }) {
                Label(project.isStarred ? "Remover Destaque" : "Destacar Projeto (Estrela)", systemImage: project.isStarred ? "star.slash" : "star.fill")
            }
            
            Button(action: onDuplicate) {
                Label("Duplicar Projeto Completo", systemImage: "doc.on.doc")
            }
            
            Menu("Mudar Status") {
                Button("🚀 Em Andamento") {
                    project.status = .active
                    try? modelContext.save()
                }
                Button("⏸️ Em Pausa") {
                    project.status = .paused
                    try? modelContext.save()
                }
                Button("✅ Concluído") {
                    project.status = .completed
                    try? modelContext.save()
                }
            }
            
            Divider()
            
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
}

// 📅 VISÃO DE CRONOGRAMA E LINHA DO TEMPO DOS PROJETOS DO SETOR
struct ProjectTimelineView: View {
    var projects: [Project]
    
    var sortedProjects: [Project] {
        projects.sorted { ($0.targetDate ?? Date.distantFuture) < ($1.targetDate ?? Date.distantFuture) }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Cronograma de Entregas")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top, 12)
                
                if sortedProjects.isEmpty {
                    Text("Nenhum projeto cadastrado.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    ForEach(sortedProjects) { project in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Circle()
                                    .fill(Color(hex: project.colorHex ?? "") ?? Color.accentColor)
                                    .frame(width: 12, height: 12)
                                
                                Text(project.name)
                                    .font(.headline)
                                
                                Spacer()
                                
                                Text(project.status.rawValue)
                                    .font(.caption2)
                                    .bold()
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.secondary.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                            
                            ProgressView(value: project.progress)
                                .tint(Color(hex: project.colorHex ?? "") ?? Color.accentColor)
                            
                            HStack {
                                Text("\(project.completedMissionsCount)/\(project.totalMissionsCount) missões salvas")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Spacer()
                                
                                if let target = project.targetDate {
                                    Text("Entrega: \(target.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.caption)
                                        .bold()
                                        .foregroundStyle(Color.accentColor)
                                } else {
                                    Text("Sem prazo definido")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(14)
                        .background(Color.secondary.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
}
