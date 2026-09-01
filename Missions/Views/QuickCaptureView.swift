import SwiftUI
import SwiftData

struct QuickCaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query var projects: [Project]
    
    @State private var title: String = ""
    @State private var priority: Priority = .medium
    @State private var dueDate: Date = Date()
    @State private var hasDueDate: Bool = true
    @State private var selectedProject: Project?
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("What needs to be done?", text: $title)
                        .font(.headline)
                        .padding(.vertical, 8)
                }
                
                Section {
                    if !projects.isEmpty {
                        Picker("Project", selection: $selectedProject) {
                            Text("None").tag(Project?.none)
                            ForEach(projects) { project in
                                Text("\(project.sector?.name ?? "") • \(project.name)").tag(Project?.some(project))
                            }
                        }
                    }
                }
                
                Section {
                    Picker("Priority", selection: $priority) {
                        Text("Low").tag(Priority.low)
                        Text("Medium").tag(Priority.medium)
                        Text("High").tag(Priority.high)
                    }
                    .pickerStyle(.segmented)
                    
                    Toggle("Set Due Date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("Date", selection: $dueDate, displayedComponents: .date)
                    }
                }
                
                Section {
                    Button(action: saveMission) {
                        Text("Save Mission")
                            .frame(maxWidth: .infinity)
                            .bold()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Quick Capture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func saveMission() {
        let newMission = Mission(
            title: title,
            dueDate: hasDueDate ? dueDate : nil,
            priority: priority
        )
        newMission.project = selectedProject
        modelContext.insert(newMission)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving mission: \(error)")
        }
    }
}
