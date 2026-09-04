import SwiftUI
import SwiftData

struct SectorsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("isPureBlack") private var isPureBlack: Bool = false
    @Query(sort: \Sector.order) var sectors: [Sector]
    
    @State private var showingAddSector = false
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if sectors.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "square.grid.2x2")
                                .font(.system(size: 48))
                                .foregroundStyle(Color.accentColor.opacity(0.7))
                            Text("Nenhum Setor Criado")
                                .font(.headline)
                            Text("Toque no botão '+' abaixo para criar seu primeiro setor (ex: Trabalho, Pessoal, Saúde).")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    } else {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(sectors) { sector in
                                NavigationLink(destination: SectorDetailView(sector: sector)) {
                                    SectorGridCard(sector: sector)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive, action: {
                                        withAnimation {
                                            modelContext.delete(sector)
                                            try? modelContext.save()
                                        }
                                    }) {
                                        Label("Excluir Setor", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
            .background(Color(uiColor: isPureBlack ? .black : .systemGroupedBackground))
            .preferredColorScheme(isPureBlack ? .dark : nil)
            .sheet(isPresented: $showingAddSector) {
                AddSectorView()
                    .preferredColorScheme(isPureBlack ? .dark : nil)
            }
        }
    }
}

struct SectorGridCard: View {
    let sector: Sector
    
    var color: Color {
        Color(hex: sector.colorHex) ?? .accentColor
    }
    
    var allMissions: [Mission] {
        (sector.projects ?? []).flatMap { $0.missions ?? [] }
    }
    
    var activeMissionsCount: Int {
        allMissions.filter { !$0.isCompleted }.count
    }
    
    var completedMissionsCount: Int {
        allMissions.filter { $0.isCompleted }.count
    }
    
    var progress: Double {
        allMissions.isEmpty ? 0 : Double(completedMissionsCount) / Double(allMissions.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: sector.iconName)
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(color)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary.opacity(0.5))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(sector.name)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Text("\(sector.projects?.count ?? 0) proj")
                    Text("•")
                    Text("\(activeMissionsCount) tarefas")
                }
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.secondary)
            }
            
            if !allMissions.isEmpty {
                ProgressView(value: progress)
                    .tint(color)
                    .padding(.top, 2)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: color.opacity(0.22), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    SectorsView()
}
