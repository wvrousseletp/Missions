import SwiftUI
import SwiftData

struct DailyReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(filter: #Predicate<Mission> { mission in
        mission.isCompleted == false
    }) var pendingMissions: [Mission]
    
    var overdueOrTodayMissions: [Mission] {
        pendingMissions.filter { mission in
            guard let dueDate = mission.dueDate else { return false }
            return Calendar.current.isDateInToday(dueDate) || dueDate < Date()
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Image(systemName: "moon.stars.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(LinearGradient(colors: [.purple, .blue], startPoint: .top, endPoint: .bottom))
                    
                    Text("Revisão de Fim de Dia")
                        .font(.title2)
                        .bold()
                    
                    Text("Organize as missões pendentes para fechar o dia com a mente leve!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.top, 20)
                
                if overdueOrTodayMissions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.green)
                        Text("Parabéns! Tudo limpo por hoje.")
                            .font(.headline)
                    }
                    .padding(.top, 40)
                } else {
                    List {
                        Section("Missões Não Concluídas (\(overdueOrTodayMissions.count))") {
                            ForEach(overdueOrTodayMissions) { mission in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(mission.title)
                                            .font(.headline)
                                        if let project = mission.project {
                                            Text(project.name)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    
                    VStack(spacing: 12) {
                        Button(action: postponeAllToTomorrow) {
                            HStack {
                                Image(systemName: "arrow.right.circle.fill")
                                Text("Adiar Tudo para Amanhã")
                                    .bold()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        
                        Button(action: moveAllToBacklog) {
                            HStack {
                                Image(systemName: "tray.full.fill")
                                Text("Mover Tudo para o Backlog")
                                    .bold()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.secondary.opacity(0.15))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Concluído") { dismiss() }
                }
            }
        }
    }
    
    private func postponeAllToTomorrow() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        withAnimation {
            for mission in overdueOrTodayMissions {
                mission.dueDate = tomorrow
            }
            try? modelContext.save()
        }
        dismiss()
    }
    
    private func moveAllToBacklog() {
        withAnimation {
            for mission in overdueOrTodayMissions {
                mission.dueDate = nil
            }
            try? modelContext.save()
        }
        dismiss()
    }
}
