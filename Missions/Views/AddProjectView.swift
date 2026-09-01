import SwiftUI
import SwiftData

struct AddProjectView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var sector: Sector
    
    @State private var name: String = ""
    @State private var description: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Informações do Projeto")) {
                    TextField("Nome do Projeto", text: $name)
                    TextField("Descrição (Opcional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Novo Projeto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar", action: saveProject)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private func saveProject() {
        let newProject = Project(name: name, projectDescription: description)
        newProject.sector = sector
        modelContext.insert(newProject)
        try? modelContext.save()
        dismiss()
    }
}
