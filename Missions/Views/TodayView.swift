import SwiftUI
import SwiftData

enum MissionFilter: String, CaseIterable {
    case all = "Todas"
    case highPriority = "🔥 Alta"
    case withChecklist = "📋 Com Checklist"
}

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(filter: #Predicate<Mission> { mission in
        mission.isCompleted == false
    }, sort: \Mission.dueDate) var todayMissions: [Mission]
    
    @Query(filter: #Predicate<Mission> { mission in
        mission.isCompleted == true
    }) var completedMissions: [Mission]
    
    @AppStorage("isPureBlack") private var isPureBlack: Bool = false
    
    @State private var selectedFilter: MissionFilter = .all
    @State private var showingQuickCapture = false
    @State private var showingFocusMode = false
    @State private var showingHelp = false
    @State private var showingStats = false
    @State private var showingSearch = false
    @State private var showingDailyReview = false
    
    var filteredTodayMissions: [Mission] {
        switch selectedFilter {
        case .all:
            return todayMissions
        case .highPriority:
            return todayMissions.filter { $0.priority == .high }
        case .withChecklist:
            return todayMissions.filter { ($0.steps?.count ?? 0) > 0 }
        }
    }
    
    // Cálculo total da carga horária estimada do dia
    var totalEstimatedMinutesToday: Int {
        todayMissions.compactMap { $0.estimatedMinutes }.reduce(0, +)
    }
    
    var formattedEstimatedTimeToday: String {
        let hours = totalEstimatedMinutesToday / 60
        let mins = totalEstimatedMinutesToday % 60
        if hours > 0 {
            return "\(hours)h \(mins)min"
        } else {
            return "\(mins) min"
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // HERO CARD: ANEL DE PROGRESSO DIÁRIO & CARGA HORÁRIA
                    HStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .stroke(Color.accentColor.opacity(0.15), lineWidth: 10)
                            
                            let total = todayMissions.count + completedMissions.filter { Calendar.current.isDateInToday($0.dueDate ?? Date()) }.count
                            let completed = completedMissions.filter { Calendar.current.isDateInToday($0.dueDate ?? Date()) }.count
                            let progress: CGFloat = total == 0 ? 0 : CGFloat(completed) / CGFloat(total)
                            
                            Circle()
                                .trim(from: 0, to: progress)
                                .stroke(
                                    LinearGradient(colors: [.accentColor, .blue], startPoint: .topLeading, endPoint: .bottomTrailing),
                                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                                )
                                .rotationEffect(.degrees(-90))
                                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                            
                            Text("\(Int(progress * 100))%")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                        .frame(width: 68, height: 68)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            let total = todayMissions.count + completedMissions.filter { Calendar.current.isDateInToday($0.dueDate ?? Date()) }.count
                            let completed = completedMissions.filter { Calendar.current.isDateInToday($0.dueDate ?? Date()) }.count
                            
                            Text("Progresso de Hoje")
                                .font(.headline)
                                .fontWeight(.bold)
                            
                            Text("\(completed) de \(total) missões concluídas")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            if totalEstimatedMinutesToday > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "hourglass")
                                        .font(.caption2)
                                    Text("Carga estimada: \(formattedEstimatedTimeToday)")
                                        .font(.caption2)
                                        .bold()
                                }
                                .foregroundStyle(Color.accentColor)
                                .padding(.top, 2)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(16)
                    .background(Color(uiColor: isPureBlack ? .secondarySystemGroupedBackground : .systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
                    
                    // CHIPS DE FILTRO RÁPIDO
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(MissionFilter.allCases, id: \.self) { filter in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedFilter = filter
                                    }
                                }) {
                                    Text(filter.rawValue)
                                        .font(.subheadline)
                                        .fontWeight(selectedFilter == filter ? .bold : .medium)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(selectedFilter == filter ? Color.accentColor : Color.secondary.opacity(0.12))
                                        .foregroundStyle(selectedFilter == filter ? .white : .primary)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // BANNER MODO FOCO (SE HOUVER MISSOES)
                    if let firstMission = filteredTodayMissions.first {
                        Button(action: {
                            showingFocusMode = true
                        }) {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(.white.opacity(0.2))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "scope")
                                        .font(.title3.bold())
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("MODO FOCO")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .kerning(1.2)
                                        .opacity(0.8)
                                    Text(firstMission.title)
                                        .font(.headline)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "play.circle.fill")
                                    .font(.title2)
                            }
                            .foregroundStyle(.white)
                            .padding(16)
                            .background(
                                LinearGradient(
                                    colors: [Color.accentColor, Color.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // LISTA DE CARDS DE MISSOES
                    if filteredTodayMissions.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 48))
                                .foregroundStyle(Color.accentColor.opacity(0.7))
                            Text("Sem Missões Pendentes")
                                .font(.headline)
                            Text("Você está em dia com seus objetivos!")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 40)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(filteredTodayMissions) { mission in
                                MissionCard(mission: mission)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 100)
            }
            .background(Color(uiColor: isPureBlack ? .black : .systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 14) {
                        Button(action: { showingHelp = true }) {
                            Image(systemName: "questionmark.circle")
                                .font(.title3)
                        }
                        
                        Button(action: { showingSearch = true }) {
                            Image(systemName: "magnifyingglass")
                                .font(.title3)
                        }
                        
                        Button(action: { showingStats = true }) {
                            Image(systemName: "chart.bar.fill")
                                .font(.title3)
                                .foregroundStyle(Color.accentColor)
                        }
                        
                        Button(action: { showingDailyReview = true }) {
                            Image(systemName: "moon.stars.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.purple)
                        }
                        
                        Button(action: {
                            withAnimation {
                                isPureBlack.toggle()
                            }
                        }) {
                            Image(systemName: isPureBlack ? "moon.fill" : "moon")
                                .font(.title3)
                                .foregroundStyle(isPureBlack ? .purple : .primary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingQuickCapture) {
                QuickCaptureView()
            }
            .sheet(isPresented: $showingHelp) {
                HelpView()
            }
            .sheet(isPresented: $showingStats) {
                StatsView()
            }
            .sheet(isPresented: $showingSearch) {
                SearchView()
            }
            .sheet(isPresented: $showingDailyReview) {
                DailyReviewView()
            }
            .fullScreenCover(isPresented: $showingFocusMode) {
                if let mission = filteredTodayMissions.first {
                    FocusModeView(mission: mission)
                }
            }
            .onAppear {
                NotificationManager.shared.requestAuthorization()
            }
        }
        .preferredColorScheme(isPureBlack ? .dark : nil)
    }
}

// CARD MODERNO DE MISSAO (INTEIRAMENTE CLICÁVEL COM MENU DE CONTEXTO)
struct MissionCard: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var mission: Mission
    @State private var isExpanded: Bool = false
    @State private var showingDetail: Bool = false
    
    var completedStepsCount: Int {
        mission.steps?.filter { $0.isCompleted }.count ?? 0
    }
    
    var totalStepsCount: Int {
        mission.steps?.count ?? 0
    }
    
    var progress: Double {
        totalStepsCount > 0 ? Double(completedStepsCount) / Double(totalStepsCount) : 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 14) {
                // BOTÃO DE CHECKLIST ANIMADO
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        mission.isCompleted.toggle()
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        
                        if mission.isCompleted {
                            NotificationManager.shared.cancelNotification(for: mission)
                            
                            if let nextMission = mission.createNextRecurrence() {
                                modelContext.insert(nextMission)
                                try? modelContext.save()
                                NotificationManager.shared.scheduleNotification(for: nextMission)
                            }
                        }
                    }
                }) {
                    ZStack {
                        Circle()
                            .stroke(mission.isCompleted ? Color.green : Color.secondary.opacity(0.3), lineWidth: 2)
                            .frame(width: 24, height: 24)
                        
                        if mission.isCompleted {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 24, height: 24)
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
                
                // DETALHES DA MISSAO
                VStack(alignment: .leading, spacing: 6) {
                    Text(mission.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .strikethrough(mission.isCompleted, color: .secondary)
                        .foregroundStyle(mission.isCompleted ? .secondary : .primary)
                        .multilineTextAlignment(.leading)
                    
                    // BADGES DE SETOR, PRIORIDADE, RECORRÊNCIA E TEMPO
                    HStack(spacing: 8) {
                        if let project = mission.project, let sector = project.sector {
                            HStack(spacing: 4) {
                                Image(systemName: sector.iconName)
                                    .font(.caption2)
                                Text("\(sector.name) • \(project.name)")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background((Color(hex: sector.colorHex) ?? Color.accentColor).opacity(0.12))
                            .foregroundStyle(Color(hex: sector.colorHex) ?? Color.accentColor)
                            .clipShape(Capsule())
                        }
                        
                        // BADGE DE PRIORIDADE
                        if mission.priority == .high {
                            Text("🔥 Alta")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.red.opacity(0.12))
                                .foregroundStyle(.red)
                                .clipShape(Capsule())
                        }
                        
                        // BADGE DE RECORRÊNCIA
                        if mission.recurrence != .none {
                            HStack(spacing: 2) {
                                Image(systemName: "repeat")
                                    .font(.caption2)
                                Text(mission.recurrence.rawValue)
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.purple.opacity(0.12))
                            .foregroundStyle(.purple)
                            .clipShape(Capsule())
                        }
                        
                        // ESTIMATIVA DE TEMPO
                        if let est = mission.estimatedMinutes {
                            HStack(spacing: 2) {
                                Image(systemName: "clock")
                                    .font(.caption2)
                                Text("\(est) min")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.12))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                        }
                    }
                    
                    // BOTÕES DE AÇÃO DIRETA NOS LINKS DETECTADOS
                    if !mission.detectedURLs.isEmpty {
                        HStack(spacing: 8) {
                            ForEach(mission.detectedURLs, id: \.self) { url in
                                Link(destination: url) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "link.circle.fill")
                                        Text(url.host ?? "Abrir Link")
                                            .font(.caption2)
                                            .bold()
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.accentColor.opacity(0.15))
                                    .foregroundStyle(Color.accentColor)
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.top, 2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    showingDetail = true
                }
                
                if totalStepsCount > 0 {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // BARRA DE PROGRESSO DAS ETAPAS
            if totalStepsCount > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("\(completedStepsCount) de \(totalStepsCount) etapas")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(progress * 100))%")
                            .font(.caption2)
                            .bold()
                            .foregroundStyle(progress == 1.0 ? .green : .accentColor)
                    }
                    
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                        .tint(progress == 1.0 ? .green : .accentColor)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    showingDetail = true
                }
            }
            
            // CHECKLIST EXPANDIDO
            if isExpanded, let steps = mission.steps?.sorted(by: { $0.order < $1.order }) {
                Divider()
                    .padding(.vertical, 4)
                
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(steps) { step in
                        StepCardRow(step: step, mission: mission)
                    }
                }
                .padding(.leading, 8)
            }
        }
        .padding(16)
        .background(
            NavigationLink(destination: MissionDetailView(mission: mission), isActive: $showingDetail) {
                EmptyView()
            }
            .opacity(0)
        )
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .onTapGesture {
            showingDetail = true
        }
        .contextMenu {
            Button(action: { showingDetail = true }) {
                Label("Editar / Detalhes", systemImage: "pencil")
            }
            
            Button(action: {
                withAnimation {
                    mission.dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
                    try? modelContext.save()
                }
            }) {
                Label("Adiar para Amanhã", systemImage: "arrow.right.circle")
            }
            
            Button(action: {
                withAnimation {
                    mission.dueDate = nil
                    try? modelContext.save()
                }
            }) {
                Label("Mover para o Backlog", systemImage: "tray.full")
            }
            
            Divider()
            
            Button(role: .destructive, action: {
                withAnimation {
                    NotificationManager.shared.cancelNotification(for: mission)
                    modelContext.delete(mission)
                    try? modelContext.save()
                }
            }) {
                Label("Excluir Missão", systemImage: "trash")
            }
        }
        .sensoryFeedback(.success, trigger: mission.isCompleted)
    }
}

// LINHA DE ETAPA NO CARD
struct StepCardRow: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var step: Step
    let mission: Mission
    
    var body: some View {
        HStack(spacing: 10) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    step.isCompleted.toggle()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    checkMissionCompletion()
                }
            }) {
                Image(systemName: step.isCompleted ? "checkmark.square.fill" : "square")
                    .foregroundStyle(step.isCompleted ? .green : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            
            Text(step.title)
                .font(.subheadline)
                .strikethrough(step.isCompleted, color: .secondary)
                .foregroundStyle(step.isCompleted ? .secondary : .primary)
            
            Spacer()
        }
        .sensoryFeedback(.impact(flexibility: .rigid), trigger: step.isCompleted)
    }
    
    private func checkMissionCompletion() {
        let allCompleted = mission.steps?.allSatisfy { $0.isCompleted } ?? false
        if allCompleted {
            mission.isCompleted = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            NotificationManager.shared.cancelNotification(for: mission)
            
            if let nextMission = mission.createNextRecurrence() {
                modelContext.insert(nextMission)
                try? modelContext.save()
                NotificationManager.shared.scheduleNotification(for: nextMission)
            }
        }
    }
}
