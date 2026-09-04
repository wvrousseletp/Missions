import SwiftUI
import SwiftData

struct DailyShutdownView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query var allMissions: [Mission]
    
    @State private var stepIndex: Int = 0
    
    var completedTodayCount: Int {
        let calendar = Calendar.current
        return allMissions.filter { m in
            m.isCompleted && calendar.isDateInToday(m.createdAt)
        }.count
    }
    
    var remainingTodayMissions: [Mission] {
        let calendar = Calendar.current
        return allMissions.filter { m in
            !m.isCompleted && m.dueDate != nil && calendar.isDateInToday(m.dueDate!)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.black, Color.indigo.opacity(0.3), Color.black],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    if stepIndex == 0 {
                        // PASSO 1: CELEBRAÇÃO DAS CONQUISTAS DE HOJE
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .fill(Color.indigo.opacity(0.2))
                                .frame(width: 120, height: 120)
                            Text("🌙")
                                .font(.system(size: 60))
                        }
                        
                        VStack(spacing: 8) {
                            Text("Hora de Encerrar o Dia")
                                .font(.title)
                                .bold()
                                .foregroundStyle(.white)
                            
                            Text("Vamos limpar sua mente para que você possa descansar 100% tranquilo.")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        
                        HStack(spacing: 16) {
                            VStack(spacing: 4) {
                                Text("\(completedTodayCount)")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundStyle(.green)
                                Text("Concluídas Hoje")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            
                            VStack(spacing: 4) {
                                Text("\(remainingTodayMissions.count)")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundStyle(remainingTodayMissions.isEmpty ? .green : .orange)
                                Text("Pendentes")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            if remainingTodayMissions.isEmpty {
                                stepIndex = 2
                            } else {
                                stepIndex = 1
                            }
                        }) {
                            Text(remainingTodayMissions.isEmpty ? "Concluir Encerramento 🧘" : "Revisar Pendências (\(remainingTodayMissions.count))")
                                .font(.headline)
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.indigo.gradient)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                        
                    } else if stepIndex == 1 {
                        // PASSO 2: ZERAR PENDÊNCIAS COM 1 TOQUE
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Pendências de Hoje")
                                .font(.title2)
                                .bold()
                                .foregroundStyle(.white)
                                .padding(.horizontal)
                                .padding(.top, 16)
                            
                            Text("Dê 1 toque para adiar para amanhã ou mover pro backlog:")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                                .padding(.horizontal)
                            
                            ScrollView {
                                VStack(spacing: 12) {
                                    ForEach(remainingTodayMissions) { mission in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(mission.title)
                                                    .font(.headline)
                                                    .foregroundStyle(.white)
                                                if let project = mission.project {
                                                    Text(project.name)
                                                        .font(.caption)
                                                        .foregroundStyle(.white.opacity(0.6))
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            HStack(spacing: 6) {
                                                Button("➡️ Amanhã") {
                                                    withAnimation {
                                                        mission.dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
                                                        try? modelContext.save()
                                                        if remainingTodayMissions.isEmpty {
                                                            stepIndex = 2
                                                        }
                                                    }
                                                }
                                                .font(.caption2)
                                                .bold()
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 6)
                                                .background(Color.blue.opacity(0.3))
                                                .foregroundStyle(.white)
                                                .clipShape(Capsule())
                                                
                                                Button("📥 Backlog") {
                                                    withAnimation {
                                                        mission.dueDate = nil
                                                        try? modelContext.save()
                                                        if remainingTodayMissions.isEmpty {
                                                            stepIndex = 2
                                                        }
                                                    }
                                                }
                                                .font(.caption2)
                                                .bold()
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 6)
                                                .background(Color.purple.opacity(0.3))
                                                .foregroundStyle(.white)
                                                .clipShape(Capsule())
                                            }
                                        }
                                        .padding(14)
                                        .background(Color.white.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            Spacer()
                            
                            Button(action: { stepIndex = 2 }) {
                                Text("Tudo Resolvido! Finalizar 🧘")
                                    .font(.headline)
                                    .bold()
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.indigo.gradient)
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 24)
                        }
                    } else {
                        // PASSO 3: MENTE 100% LIMPA
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.2))
                                .frame(width: 130, height: 130)
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(.green)
                        }
                        
                        VStack(spacing: 10) {
                            Text("Sua Mente está 100% Limpa! 🧘")
                                .font(.title2)
                                .bold()
                                .foregroundStyle(.white)
                            
                            Text("Todas as pendências foram organizadas. Você não precisa se preocupar com nada hoje. Boa noite!")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        
                        Spacer()
                        
                        Button(action: { dismiss() }) {
                            Text("Concluir Encerramento")
                                .font(.headline)
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.green.gradient)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
    }
}
