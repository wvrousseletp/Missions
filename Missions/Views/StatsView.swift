import SwiftUI
import SwiftData

struct StatsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Query var allMissions: [Mission]
    @Query var allSectors: [Sector]
    @Query var allProjects: [Project]
    
    var completedMissionsCount: Int {
        allMissions.filter { $0.isCompleted }.count
    }
    
    var pendingMissionsCount: Int {
        allMissions.filter { !$0.isCompleted }.count
    }
    
    var totalMissionsCount: Int {
        allMissions.count
    }
    
    var completionRate: Int {
        totalMissionsCount == 0 ? 0 : Int((Double(completedMissionsCount) / Double(totalMissionsCount)) * 100)
    }
    
    var completedThisWeekCount: Int {
        let calendar = Calendar.current
        let now = Date()
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) else { return 0 }
        
        return allMissions.filter { mission in
            mission.isCompleted && (mission.dueDate ?? mission.createdAt) >= weekAgo
        }.count
    }
    
    // GERAÇÃO DE RELATÓRIO FORMATADO PARA COMPARTILHAMENTO
    var formattedReportText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "dd/MM/yyyy"
        let todayStr = formatter.string(from: Date())
        
        var report = "📊 RELATÓRIO DE PRODUTIVIDADE - MISSIONS (\(todayStr))\n"
        report += "--------------------------------------\n"
        report += "✅ Missões Concluídas: \(completedMissionsCount)\n"
        report += "⏳ Missões Pendentes: \(pendingMissionsCount)\n"
        report += "⚡ Taxa de Sucesso: \(completionRate)%\n"
        report += "🚀 Concluídas nos últimos 7 dias: \(completedThisWeekCount)\n\n"
        
        report += "📁 DESEMPENHO POR SETOR:\n"
        for sector in allSectors {
            let sectorMissions = (sector.projects ?? []).flatMap { $0.missions ?? [] }
            let completed = sectorMissions.filter { $0.isCompleted }.count
            let total = sectorMissions.count
            report += "• \(sector.name): \(completed)/\(total) concluídas\n"
        }
        
        return report
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // BOTÃO COMPARTILHAR RELATÓRIO
                    ShareLink(item: formattedReportText) {
                        HStack {
                            Image(systemName: "square.and.arrow.up.fill")
                            Text("Exportar Relatório de Progresso")
                                .bold()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(Color.accentColor.gradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color.accentColor.opacity(0.3), radius: 6, x: 0, y: 3)
                    }
                    
                    // CARDS DE RESUMO EM GRID
                    HStack(spacing: 12) {
                        StatCard(
                            title: "Concluídas",
                            value: "\(completedMissionsCount)",
                            icon: "checkmark.circle.fill",
                            color: .green
                        )
                        
                        StatCard(
                            title: "Pendentes",
                            value: "\(pendingMissionsCount)",
                            icon: "clock.fill",
                            color: .orange
                        )
                        
                        StatCard(
                            title: "Taxa de Sucesso",
                            value: "\(completionRate)%",
                            icon: "chart.line.uptrend.xyaxis",
                            color: .accentColor
                        )
                    }
                    
                    // CARD HERO DE PRODUTIVIDADE SEMANAL
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(Color.purple.opacity(0.15))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "bolt.fill")
                                    .font(.title3)
                                    .foregroundStyle(.purple)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Produtividade da Semana")
                                    .font(.headline)
                                Text("Últimos 7 dias")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("\(completedThisWeekCount) concluídas")
                                .font(.subheadline)
                                .bold()
                                .foregroundStyle(.purple)
                        }
                        
                        ProgressView(value: Double(completedThisWeekCount), total: max(Double(totalMissionsCount), 1.0))
                            .progressViewStyle(.linear)
                            .tint(.purple)
                    }
                    .padding(16)
                    .background(Color(uiColor: .systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
                    
                    // DISTRIBUIÇÃO POR SETOR
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Desempenho por Setor")
                            .font(.headline)
                            .padding(.leading, 4)
                        
                        if allSectors.isEmpty {
                            Text("Nenhum setor cadastrado ainda.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(allSectors) { sector in
                                    SectorStatRow(sector: sector)
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Estatísticas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fechar") { dismiss() }
                }
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
    }
}

struct SectorStatRow: View {
    let sector: Sector
    
    var color: Color {
        Color(hex: sector.colorHex) ?? .accentColor
    }
    
    var sectorMissions: [Mission] {
        let projects = sector.projects ?? []
        return projects.flatMap { $0.missions ?? [] }
    }
    
    var completedCount: Int {
        sectorMissions.filter { $0.isCompleted }.count
    }
    
    var totalCount: Int {
        sectorMissions.count
    }
    
    var progress: Double {
        totalCount == 0 ? 0 : Double(completedCount) / Double(totalCount)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: sector.iconName)
                        .foregroundStyle(color)
                    Text(sector.name)
                        .font(.headline)
                }
                
                Spacer()
                
                Text("\(completedCount)/\(totalCount)")
                    .font(.subheadline)
                    .bold()
                    .foregroundStyle(.secondary)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(color)
        }
        .padding(14)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
    }
}
