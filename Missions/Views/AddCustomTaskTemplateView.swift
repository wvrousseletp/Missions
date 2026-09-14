import SwiftUI
import SwiftData

struct AddCustomTaskTemplateView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var templateToEdit: CustomTaskTemplate? = nil
    
    @State private var title: String = ""
    @State private var category: String = "Pessoal"
    @State private var details: String = ""
    @State private var estimatedMinutes: Int = 30
    @State private var steps: [String] = []
    @State private var newStepTitle: String = ""
    
    let categories = ["Pessoal", "Trabalho", "Espiritual", "Viagem", "Saúde", "Casa", "Finanças"]
    
    init(templateToEdit: CustomTaskTemplate? = nil) {
        self.templateToEdit = templateToEdit
        if let t = templateToEdit {
            _title = State(initialValue: t.title)
            _category = State(initialValue: t.category)
            _details = State(initialValue: t.details)
            _estimatedMinutes = State(initialValue: t.estimatedMinutes)
            _steps = State(initialValue: t.steps)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Nome do Padrão / Tarefa")) {
                    TextField("Ex: Ir para Retiro, Viagem a Trabalho...", text: $title)
                        .font(.headline)
                    
                    Picker("Categoria", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                }
                
                Section(header: Text("Anotações ou Instruções Padrão")) {
                    TextField("Detalhes da tarefa...", text: $details, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section(header: Text("Estimativa de Tempo")) {
                    Stepper("\(estimatedMinutes) minutos de foco", value: $estimatedMinutes, in: 5...240, step: 15)
                }
                
                Section(header: Text("Checklist Padrão (Passos da Tarefa)")) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, stepTitle in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.accentColor)
                            Text(stepTitle)
                            Spacer()
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                withAnimation {
                                    if index < steps.count {
                                        steps.remove(at: index)
                                    }
                                }
                            } label: {
                                Label("Excluir Passo", systemImage: "trash")
                            }
                        }
                    }
                    .onDelete(perform: removeStep)
                    
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.accentColor)
                        
                        TextField("Adicionar novo passo ao checklist...", text: $newStepTitle)
                            .onSubmit {
                                addStep()
                            }
                        
                        if !newStepTitle.isEmpty {
                            Button("Adicionar", action: addStep)
                                .font(.caption)
                                .bold()
                        }
                    }
                    
                    Button(action: pasteClipboardSteps) {
                        HStack {
                            Image(systemName: "doc.on.clipboard.fill")
                                .foregroundStyle(Color.accentColor)
                            Text("Colar Lista do WhatsApp/Notas como Passos")
                                .font(.subheadline)
                                .bold()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle(templateToEdit == nil ? "Novo Padrão de Tarefa" : "Editar Padrão")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancelar") { dismiss() },
                trailing: Button("Salvar", action: saveTemplate)
                    .bold()
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
        }
    }
    
    private func addStep() {
        let trimmed = newStepTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        steps.append(trimmed)
        newStepTitle = ""
    }
    
    private func removeStep(at offsets: IndexSet) {
        steps.remove(atOffsets: offsets)
    }
    
    private func pasteClipboardSteps() {
        guard let text = UIPasteboard.general.string, !text.isEmpty else { return }
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        for line in lines {
            let clean = line.replacingOccurrences(of: #"^([\-\*\•]|\d+[\.\)])\s+"#, with: "", options: .regularExpression)
            if !clean.isEmpty {
                steps.append(clean)
            }
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    private func saveTemplate() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        
        if let existing = templateToEdit {
            existing.title = trimmedTitle
            existing.category = category
            existing.details = details
            existing.estimatedMinutes = estimatedMinutes
            existing.steps = steps
        } else {
            let newT = CustomTaskTemplate(
                title: trimmedTitle,
                category: category,
                details: details,
                estimatedMinutes: estimatedMinutes,
                steps: steps
            )
            modelContext.insert(newT)
        }
        
        try? modelContext.save()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}
