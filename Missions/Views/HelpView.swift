import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("O Básico")) {
                    HelpRow(icon: "sun.max.fill", color: .orange, title: "Hoje", description: "Onde ficam as missões que precisam da sua atenção no dia atual.")
                    HelpRow(icon: "calendar", color: .red, title: "Semana", description: "Planeje seus próximos dias e visualize os prazos chegando.")
                    HelpRow(icon: "square.grid.2x2.fill", color: .blue, title: "Setores & Projetos", description: "Organize sua vida. Setores (ex: Pessoal, Trabalho) contêm Projetos, e Projetos contêm Missões.")
                    HelpRow(icon: "tray.full.fill", color: .gray, title: "Backlog", description: "Uma gaveta para ideias e missões que não têm uma data definida ainda.")
                }
                
                Section(header: Text("Dicas de Produtividade")) {
                    HelpRow(icon: "scope", color: .accentColor, title: "Modo Foco", description: "Toque em 'Entrar no Modo Foco' na aba Hoje para se concentrar em uma etapa de cada vez, com um timer integrado para evitar distrações.")
                    HelpRow(icon: "hand.draw.fill", color: .purple, title: "Gestos", description: "Deslize uma missão para a direita na lista para concluí-la instantaneamente, ou para a esquerda para adiá-la ou excluí-la.")
                    HelpRow(icon: "checklist", color: .green, title: "Etapas", description: "Você pode quebrar missões complexas em etapas menores clicando na missão e adicionando um checklist.")
                }
            }
            .navigationTitle("Como usar o Missions")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct HelpRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 30)
                
                Text(title)
                    .font(.headline)
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 42)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HelpView()
}
