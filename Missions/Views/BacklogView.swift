import SwiftUI
import SwiftData

struct BacklogView: View {
    @AppStorage("isPureBlack") private var isPureBlack: Bool = false
    
    @Query(filter: #Predicate<Mission> { mission in
        mission.isCompleted == false
    }, sort: \Mission.createdAt, order: .reverse) var allPendingMissions: [Mission]
    
    var backlogMissions: [Mission] {
        allPendingMissions.filter { $0.dueDate == nil }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if backlogMissions.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "tray")
                                .font(.system(size: 48))
                                .foregroundStyle(Color.accentColor.opacity(0.7))
                            Text("Backlog Vazio")
                                .font(.headline)
                            Text("Todas as suas missões estão agendadas para datas específicas!")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    } else {
                        ForEach(backlogMissions) { mission in
                            MissionCard(mission: mission)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
            .background(Color(uiColor: isPureBlack ? .black : .systemGroupedBackground))
            .preferredColorScheme(isPureBlack ? .dark : nil)
        }
    }
}
