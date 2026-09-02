import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Query var allMissions: [Mission]
    
    @State private var searchText: String = ""
    @State private var selectedCategory: SearchCategory = .all
    
    enum SearchCategory: String, CaseIterable {
        case all = "Todas"
        case pending = "Pendentes"
        case completed = "Concluídas"
        case highPriority = "🔥 Alta"
        case withNotes = "📝 Com Notas"
    }
    
    var searchResults: [Mission] {
        allMissions.filter { mission in
            // Filtro por Texto
            let matchesText = searchText.isEmpty ||
                mission.title.localizedCaseInsensitiveContains(searchText) ||
                mission.details.localizedCaseInsensitiveContains(searchText) ||
                (mission.project?.name.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (mission.project?.sector?.name.localizedCaseInsensitiveContains(searchText) ?? false)
            
            // Filtro por Categoria
            let matchesCategory: Bool
            switch selectedCategory {
            case .all:
                matchesCategory = true
            case .pending:
                matchesCategory = !mission.isCompleted
            case .completed:
                matchesCategory = mission.isCompleted
            case .highPriority:
                matchesCategory = mission.priority == .high
            case .withNotes:
                matchesCategory = !mission.details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            
            return matchesText && matchesCategory
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // CHIPS DE FILTRO DE BUSCA
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(SearchCategory.allCases, id: \.self) { category in
                            Button(action: {
                                withAnimation {
                                    selectedCategory = category
                                }
                            }) {
                                Text(category.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(selectedCategory == category ? .bold : .medium)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(selectedCategory == category ? Color.accentColor : Color.secondary.opacity(0.12))
                                    .foregroundStyle(selectedCategory == category ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .background(Color.secondary.opacity(0.05))
                
                // RESULTADOS DA BUSCA
                ScrollView {
                    VStack(spacing: 12) {
                        if searchResults.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 48))
                                    .foregroundStyle(Color.accentColor.opacity(0.6))
                                Text("Nenhum resultado encontrado")
                                    .font(.headline)
                                Text("Tente buscar por outras palavras-chave ou altere os filtros acima.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                        } else {
                            ForEach(searchResults) { mission in
                                MissionCard(mission: mission)
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .searchable(text: $searchText, prompt: "Buscar missões, notas ou setores...")
            .navigationTitle("Busca Inteligente")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Concluído") { dismiss() }
                }
            }
        }
    }
}
