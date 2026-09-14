import SwiftUI
import SwiftData

struct TemplateManagerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \CustomTaskTemplate.createdAt, order: .reverse) var customTaskTemplates: [CustomTaskTemplate]
    @Query(sort: \CustomProjectTemplate.createdAt, order: .reverse) var customProjectTemplates: [CustomProjectTemplate]
    
    @State private var selectedSegment: Int = 0 // 0: Padrões de Tarefas, 1: Modelos de Projetos
    @State private var showingAddTaskTemplate = false
    @State private var taskTemplateToEdit: CustomTaskTemplate? = nil
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Tipo de Template", selection: $selectedSegment) {
                    Text("📋 Padrões de Tarefas").tag(0)
                    Text("📁 Modelos de Projetos").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                if selectedSegment == 0 {
                    // SEÇÃO DE PADRÕES DE TAREFAS / CHECKLISTS
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Seus Padrões de Tarefas")
                                    .font(.headline)
                                Spacer()
                                Button(action: {
                                    taskTemplateToEdit = nil
                                    showingAddTaskTemplate = true
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Criar Padrão")
                                    }
                                    .font(.subheadline)
                                    .bold()
                                    .foregroundStyle(Color.accentColor)
                                }
                            }
                            .padding(.horizontal)
                            
                            if customTaskTemplates.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "list.bullet.rectangle.portrait")
                                        .font(.system(size: 44))
                                        .foregroundStyle(Color.accentColor.opacity(0.6))
                                    Text("Nenhum Padrão Personalizado")
                                        .font(.headline)
                                    Text("Crie padrões de tarefas frequentes (ex: 'Ir para retiro', 'Viagem de carro') com checklists prontos.")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 32)
                                    
                                    Button(action: {
                                        taskTemplateToEdit = nil
                                        showingAddTaskTemplate = true
                                    }) {
                                        Text("Criar Primeiro Padrão de Tarefa")
                                            .bold()
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 10)
                                            .background(Color.accentColor)
                                            .foregroundStyle(.white)
                                            .clipShape(Capsule())
                                    }
                                    .padding(.top, 8)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 30)
                            } else {
                                ForEach(customTaskTemplates) { taskTemplate in
                                    VStack(alignment: .leading, spacing: 10) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(taskTemplate.title)
                                                    .font(.headline)
                                                    .bold()
                                                
                                                HStack(spacing: 6) {
                                                    Text(taskTemplate.category)
                                                        .font(.caption2)
                                                        .bold()
                                                        .padding(.horizontal, 8)
                                                        .padding(.vertical, 3)
                                                        .background(Color.accentColor.opacity(0.12))
                                                        .foregroundStyle(Color.accentColor)
                                                        .clipShape(Capsule())
                                                    
                                                    Text("•")
                                                        .font(.caption2)
                                                        .foregroundStyle(.secondary)
                                                    
                                                    Text("\(taskTemplate.steps.count) passos no checklist")
                                                        .font(.caption2)
                                                        .foregroundStyle(.secondary)
                                                }
                                            }
                                            Spacer()
                                            
                                            Button(action: {
                                                taskTemplateToEdit = taskTemplate
                                                showingAddTaskTemplate = true
                                            }) {
                                                Image(systemName: "pencil.circle.fill")
                                                    .font(.title2)
                                                    .foregroundStyle(Color.accentColor)
                                            }
                                        }
                                        
                                        if !taskTemplate.details.isEmpty {
                                            Text(taskTemplate.details)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(2)
                                        }
                                        
                                        Divider()
                                        
                                        // Pré-visualização dos passos
                                        VStack(alignment: .leading, spacing: 4) {
                                            ForEach(taskTemplate.steps.prefix(4), id: \.self) { step in
                                                HStack(spacing: 6) {
                                                    Image(systemName: "circle")
                                                        .font(.caption2)
                                                        .foregroundStyle(.secondary)
                                                    Text(step)
                                                        .font(.caption)
                                                }
                                            }
                                            if taskTemplate.steps.count > 4 {
                                                Text("+ mais \(taskTemplate.steps.count - 4) passos...")
                                                    .font(.caption2)
                                                    .italic()
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                    .padding(14)
                                    .background(Color.secondary.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .padding(.horizontal)
                                    .contextMenu {
                                        Button(action: {
                                            taskTemplateToEdit = taskTemplate
                                            showingAddTaskTemplate = true
                                        }) {
                                            Label("Editar Padrão", systemImage: "pencil")
                                        }
                                        
                                        Button(role: .destructive, action: {
                                            withAnimation {
                                                modelContext.delete(taskTemplate)
                                                try? modelContext.save()
                                            }
                                        }) {
                                            Label("Excluir Padrão", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                } else {
                    // SEÇÃO DE MODELOS DE PROJETOS
                    TemplatePickerView()
                }
            }
            .navigationTitle("Biblioteca de Templates")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Fechar") { dismiss() }
            )
            .sheet(isPresented: $showingAddTaskTemplate) {
                AddCustomTaskTemplateView(templateToEdit: taskTemplateToEdit)
            }
        }
    }
}
