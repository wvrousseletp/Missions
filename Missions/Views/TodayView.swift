import SwiftUI
import SwiftData

enum MissionFilter: String, CaseIterable {
    case all = "Todas"
    case highPriority = "🔥 Alta"
    case withChecklist = "📋 Com Checklist"
}

struct TodayView: View {
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
    
    var body: some View {
        NavigationStack {
            List {
                // ANEL DE PROGRESSO
                Section {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 8)
                            
                            let total = todayMissions.count + completedMissions.filter { Calendar.current.isDateInToday($0.dueDate ?? Date()) }.count
                            let completed = completedMissions.filter { Calendar.current.isDateInToday($0.dueDate ?? Date()) }.count
                            let progress: CGFloat = total == 0 ? 0 : CGFloat(completed) / CGFloat(total)
                            
                            Circle()
                                .trim(from: 0, to: progress)
                                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .animation(.spring(), value: progress)
                            
                            Text("\(Int(progress * 100))%")
                                .font(.caption)
                                .bold()
                        }
                        .frame(width: 60, height: 60)
                        
                        VStack(alignment: .leading) {
                            Text("Seu Progresso")
                                .font(.headline)
                            let total = todayMissions.count + completedMissions.filter { Calendar.current.isDateInToday($0.dueDate ?? Date()) }.count
                            let completed = completedMissions.filter { Calendar.current.isDateInToday($0.dueDate ?? Date()) }.count
                            Text("\(completed) de \(total) missões concluídas hoje")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.clear)
                
                // CHIPS DE FILTRO RÁPIDO
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(MissionFilter.allCases, id: \.self) { filter in
                                Button(action: {
                                    withAnimation {
                                        selectedFilter = filter
                                    }
                                }) {
                                    Text(filter.rawValue)
                                        .font(.subheadline)
                                        .fontWeight(selectedFilter == filter ? .bold : .regular)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 6)
                                        .background(selectedFilter == filter ? Color.accentColor : Color.secondary.opacity(0.15))
                                        .foregroundStyle(selectedFilter == filter ? .white : .primary)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            
                if filteredTodayMissions.isEmpty {
                    ContentUnavailableView("Sem Missões Aqui", systemImage: "sparkles", description: Text("Nenhuma missão corresponde ao filtro."))
                } else {
                    Section {
                        if let firstMission = filteredTodayMissions.first {
                            Button(action: {
                                showingFocusMode = true
                            }) {
                                HStack {
                                    Image(systemName: "scope")
                                    Text("Entrar no Modo Foco")
                                        .bold()
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .foregroundStyle(.white)
                                .padding()
                                .background(Color.accentColor.gradient)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }
                    }
                    
                    Section("Missões Pendentes") {
                        ForEach(filteredTodayMissions) { mission in
                            MissionRow(mission: mission)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 12) {
                        Button(action: { showingHelp = true }) {
                            Image(systemName: "questionmark.circle")
                        }
                        
                        Button(action: {
                            withAnimation {
                                isPureBlack.toggle()
                            }
                        }) {
                            Image(systemName: isPureBlack ? "moon.stars.fill" : "moon")
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
            .fullScreenCover(isPresented: $showingFocusMode) {
                if let mission = filteredTodayMissions.first {
                    FocusModeView(mission: mission)
                }
            }
        }
        .preferredColorScheme(isPureBlack ? .dark : nil)
    }
}

struct MissionRow: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var mission: Mission
    @State private var isExpanded: Bool = false
    
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button(action: {
                    withAnimation {
                        mission.isCompleted.toggle()
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                }) {
                    Image(systemName: mission.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(mission.isCompleted ? .green : .gray)
                        .font(.title3)
                }
                .buttonStyle(.plain)
                
                NavigationLink(destination: MissionDetailView(mission: mission)) {
                    VStack(alignment: .leading) {
                        Text(mission.title)
                            .font(.headline)
                            .strikethrough(mission.isCompleted, color: .gray)
                        
                        if let project = mission.project, let sector = project.sector {
                            Text("\(sector.name) • \(project.name)")
                                .font(.caption)
                                .foregroundStyle(Color(hex: sector.colorHex) ?? .secondary)
                        }
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                if totalStepsCount > 0 {
                    Button(action: {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            if totalStepsCount > 0 {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .tint(progress == 1.0 ? .green : .accentColor)
                
                Text("\(completedStepsCount)/\(totalStepsCount) etapas concluídas")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            if isExpanded, let steps = mission.steps?.sorted(by: { $0.order < $1.order }) {
                Divider()
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(steps) { step in
                        StepRow(step: step, mission: mission)
                    }
                }
                .padding(.leading, 24)
                .padding(.top, 8)
            }
        }
        .padding(.vertical, 4)
        .sensoryFeedback(.success, trigger: mission.isCompleted)
        .swipeActions(edge: .leading) {
            Button {
                withAnimation {
                    mission.isCompleted = true
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            } label: {
                Label("Concluir", systemImage: "checkmark")
            }
            .tint(.green)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                withAnimation {
                    modelContext.delete(mission)
                }
            } label: {
                Label("Excluir", systemImage: "trash")
            }
            
            Button {
                withAnimation {
                    mission.dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
                }
            } label: {
                Label("Adiar", systemImage: "arrow.right.circle")
            }
            .tint(.orange)
        }
    }
}

struct StepRow: View {
    @Bindable var step: Step
    let mission: Mission
    
    var body: some View {
        HStack {
            Button(action: {
                withAnimation {
                    step.isCompleted.toggle()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    checkMissionCompletion()
                }
            }) {
                Image(systemName: step.isCompleted ? "checkmark.square.fill" : "square")
                    .foregroundStyle(step.isCompleted ? .green : .gray)
            }
            .buttonStyle(.plain)
            
            Text(step.title)
                .font(.subheadline)
                .strikethrough(step.isCompleted, color: .gray)
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
        }
    }
}
