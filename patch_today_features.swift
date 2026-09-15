import Foundation

let path = "Missions/Views/TodayView.swift"
var content = try String(contentsOfFile: path)

// Add State for inline Pomodoro
let stateVars = """
    @State private var showingDailyShutdown = false
    
    // Novas variaveis para Produtividade
    @State private var isListHidden: Bool = true
    @State private var pomodoroTimeRemaining: Int = 25 * 60
    @State private var isPomodoroRunning: Bool = false
    @State private var pomodoroTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
"""
content = content.replacingOccurrences(of: "@State private var showingDailyShutdown = false", with: stateVars)

// Add Routine Pills and Focus List Toggle
let newUI = """
                        // BANNER MODO FOCO INLINE
                        if let firstMission = filteredTodayMissions.filter({ !$0.isRoutine }).first {
                            VStack(spacing: 0) {
                                HStack(spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .fill(.white.opacity(0.2))
                                            .frame(width: 44, height: 44)
                                        
                                        if isPomodoroRunning {
                                            Text("\\(pomodoroTimeRemaining / 60):\\(String(format: "%02d", pomodoroTimeRemaining % 60))")
                                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        } else {
                                            Image(systemName: "scope")
                                                .font(.title3.bold())
                                        }
                                        
                                        Circle()
                                            .trim(from: 0, to: CGFloat(pomodoroTimeRemaining) / CGFloat(25 * 60))
                                            .stroke(Color.white, lineWidth: 2)
                                            .rotationEffect(.degrees(-90))
                                    }
                                    .onReceive(pomodoroTimer) { _ in
                                        if isPomodoroRunning && pomodoroTimeRemaining > 0 {
                                            pomodoroTimeRemaining -= 1
                                        } else if pomodoroTimeRemaining == 0 {
                                            isPomodoroRunning = false
                                        }
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
                                    
                                    Button(action: {
                                        withAnimation {
                                            if isPomodoroRunning {
                                                isPomodoroRunning = false
                                            } else {
                                                if pomodoroTimeRemaining == 0 { pomodoroTimeRemaining = 25 * 60 }
                                                isPomodoroRunning = true
                                            }
                                        }
                                    }) {
                                        Image(systemName: isPomodoroRunning ? "pause.circle.fill" : "play.circle.fill")
                                            .font(.system(size: 32))
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(16)
                                .background(
                                    LinearGradient(
                                        colors: [Color.accentColor, Color.purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundStyle(.white)
                                
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        isListHidden.toggle()
                                    }
                                }) {
                                    HStack {
                                        Spacer()
                                        Text(isListHidden ? "Mostrar Outras Missões" : "Ocultar Missões")
                                            .font(.caption)
                                            .bold()
                                        Image(systemName: isListHidden ? "chevron.down" : "chevron.up")
                                            .font(.caption)
                                        Spacer()
                                    }
                                    .padding(.vertical, 8)
                                    .background(Color.accentColor.opacity(0.1))
                                    .foregroundStyle(Color.accentColor)
                                }
                                .buttonStyle(.plain)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        
                        // ROTINAS (PILLS)
                        let routines = filteredTodayMissions.filter { $0.isRoutine }
                        if !routines.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Rotinas de Hoje")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 4)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(routines) { routine in
                                            Button(action: {
                                                withAnimation {
                                                    routine.isCompleted = true
                                                    try? modelContext.save()
                                                    // TODO: maybe handle recurrence here
                                                }
                                            }) {
                                                HStack(spacing: 6) {
                                                    Image(systemName: "circle")
                                                    Text(routine.title)
                                                        .font(.subheadline)
                                                        .bold()
                                                }
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 8)
                                                .background(Color(uiColor: .tertiarySystemGroupedBackground))
                                                .foregroundStyle(.primary)
                                                .clipShape(Capsule())
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // LISTA DE CARDS DE MISSOES PENDENTES
                        if (!isListHidden || filteredTodayMissions.filter { !$0.isRoutine }.isEmpty) {
"""

// Encontrar e substituir a seção de foco existente e a declaração da lista
let oldFocusSection = """
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
                        
                        // LISTA DE CARDS DE MISSOES PENDENTES
"""

content = content.replacingOccurrences(of: oldFocusSection, with: newUI)

// Filtrar as missões não rotina da lista principal
content = content.replacingOccurrences(of: "ForEach(filteredTodayMissions) { mission in", with: "ForEach(filteredTodayMissions.filter { !$0.isRoutine }) { mission in")

// No final do bloco If isListHidden, precisamos fechar a chave?
// old:
//                        // LISTA DE CARDS DE MISSOES PENDENTES
//                        if filteredTodayMissions.isEmpty && completedTodayMissions.isEmpty {
// newUI deixou aberto `if (!isListHidden || filteredTodayMissions.filter { !$0.isRoutine }.isEmpty) {` - wait! Se eu abrir um IF ali, eu preciso fechar. 
// O melhor é fazer uma substituição mais precisa.
