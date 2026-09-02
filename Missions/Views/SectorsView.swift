import SwiftUI
import SwiftData

struct SectorsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Sector.order) var sectors: [Sector]
    
    @State private var showingAddSector = false
    
    var body: some View {
        NavigationStack {
            List {
                if sectors.isEmpty {
                    ContentUnavailableView("Sem setores", systemImage: "square.grid.2x2", description: Text("Crie seu primeiro setor para organizar seus projetos."))
                } else {
                    ForEach(sectors) { sector in
                        NavigationLink(destination: SectorDetailView(sector: sector)) {
                            HStack(spacing: 16) {
                                Image(systemName: sector.iconName)
                                    .font(.title2)
                                    .foregroundStyle(Color(hex: sector.colorHex) ?? .primary)
                                    .frame(width: 32)
                                
                                Text(sector.name)
                                    .font(.headline)
                                
                                Spacer()
                                
                                Text("\(sector.projects?.count ?? 0) projetos")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete(perform: deleteSectors)
                }
            }
            .listStyle(.insetGrouped)
            .sheet(isPresented: $showingAddSector) {
                AddSectorView()
            }
        }
    }
    
    private func deleteSectors(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(sectors[index])
            }
            try? modelContext.save()
        }
    }
}

#Preview {
    SectorsView()
}
