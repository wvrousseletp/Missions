import SwiftUI
import SwiftData

struct AddProjectView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var sector: Sector
    
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var status: ProjectStatus = .active
    @State private var hasTargetDate: Bool = false
    @State private var targetDate: Date = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @State private var selectedColorHex: String = "#007AFF"
    
    let colors = ["#007AFF", "#34C759", "#FF9500", "#FF3B30", "#AF52DE", "#5856D6", "#FF2D55", "#A2845E"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Informações do Projeto")) {
                    TextField("Nome do Projeto (ex: Nova Rota de Entregas)", text: $name)
                    TextField("Descrição ou objetivo...", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section(header: Text("Status & Planejamento")) {
                    Picker("Status do Projeto", selection: $status) {
                        ForEach(ProjectStatus.allCases, id: \.self) { st in
                            Text(st.rawValue).tag(st)
                        }
                    }
                    
                    Toggle("Definir Prazo de Conclusão", isOn: $hasTargetDate)
                    
                    if hasTargetDate {
                        DatePicker("Prazo Final", selection: $targetDate, displayedComponents: [.date])
                            .environment(\.locale, Locale(identifier: "pt_BR"))
                    }
                }
                
                Section(header: Text("Cor de Destaque")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(colors, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex) ?? .blue)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: selectedColorHex == hex ? 3 : 0)
                                )
                                .onTapGesture {
                                    selectedColorHex = hex
                                }
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
            .navigationTitle("Novo Projeto")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancelar") { dismiss() },
                trailing: Button("Salvar", action: saveProject)
                    .bold()
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            )
        }
    }
    
    private func saveProject() {
        let newProject = Project(
            name: name,
            projectDescription: description,
            status: status,
            colorHex: selectedColorHex,
            targetDate: hasTargetDate ? targetDate : nil
        )
        newProject.sector = sector
        modelContext.insert(newProject)
        try? modelContext.save()
        dismiss()
    }
}
