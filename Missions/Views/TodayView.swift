import SwiftUI
import SwiftData

struct TodayView: View {
    @Query(filter: #Predicate<Mission> { mission in
        mission.isCompleted == false
    }, sort: \Mission.dueDate) var todayMissions: [Mission]
    
    @State private var showingQuickCapture = false
    @State private var showingFocusMode = false
    
    var body: some View {
        NavigationStack {
            List {
                if todayMissions.isEmpty {
                    ContentUnavailableView("Sem Missões Hoje", systemImage: "sparkles", description: Text("Você está em dia!"))
                } else {
                    Section {
                        if let firstMission = todayMissions.first {
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
                        ForEach(todayMissions) { mission in
                            MissionRow(mission: mission)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Hoje")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        showingQuickCapture = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingQuickCapture) {
                QuickCaptureView()
            }
            .fullScreenCover(isPresented: $showingFocusMode) {
                if let mission = todayMissions.first {
                    FocusModeView(mission: mission)
                }
            }
        }
    }
}

struct MissionRow: View {
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
    }
    
    private func checkMissionCompletion() {
        let allCompleted = mission.steps?.allSatisfy { $0.isCompleted } ?? false
        if allCompleted {
            mission.isCompleted = true
        }
    }
}
