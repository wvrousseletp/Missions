import SwiftUI
import SwiftData

struct TemplatePickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let project: Project
    var onApplied: (() -> Void)? = nil
    
    @State private var selectedTemplate: ProjectTemplate? = nil
    @State private var showingConfirmation = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.purple.opacity(0.18))
                                .frame(width: 44, height: 44)
                            Image(systemName: "wand.and.stars")
                                .font(.title2)
                                .foregroundStyle(.purple)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Modelos Prontos de Projetos")
                                .font(.headline)
                                .bold()
                            Text("Injete uma estrutura pronta de missões e checklists no projeto '\(project.name)' com 1 toque.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    
                    ForEach(ProjectTemplateManager.shared.templates) { template in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: template.icon)
                                    .font(.title)
                                    .foregroundStyle(Color.accentColor)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(template.name)
                                        .font(.headline)
                                        .bold()
                                    
                                    Text(template.description)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    
                                    Text("\(template.missions.count) missões • \(template.missions.flatMap { $0.steps }.count) etapas inclusas")
                                        .font(.caption2)
                                        .bold()
                                        .foregroundStyle(Color.accentColor)
                                }
                                
                                Spacer()
                            }
                            
                            Divider()
                            
                            // Amostra das missões do template
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(template.missions, id: \.title) { mission in
                                    HStack(spacing: 6) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.caption2)
                                            .foregroundStyle(.green)
                                        Text(mission.title)
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                        Spacer()
                                        Text(mission.phase)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding(.leading, 4)
                            
                            Button(action: {
                                selectedTemplate = template
                                showingConfirmation = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.app.fill")
                                    Text("Usar Este Template no Projeto")
                                        .bold()
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.accentColor)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .padding(.top, 4)
                        }
                        .padding(16)
                        .background(Color.secondary.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 24)
            }
            .navigationTitle("Templates de Projetos")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancelar") { dismiss() }
            )
            .alert("Aplicar Template?", isPresented: $showingConfirmation) {
                Button("Cancelar", role: .cancel) { }
                Button("Aplicar Template") {
                    if let t = selectedTemplate {
                        ProjectTemplateManager.shared.applyTemplate(t, to: project, in: modelContext)
                        onApplied?()
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        dismiss()
                    }
                }
            } message: {
                if let t = selectedTemplate {
                    Text("As \(t.missions.count) missões do template '\(t.name)' serão adicionadas ao projeto '\(project.name)'.")
                } else {
                    Text("Deseja aplicar as missões ao projeto?")
                }
            }
        }
    }
}
