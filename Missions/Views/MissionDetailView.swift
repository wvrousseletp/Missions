import SwiftUI
import SwiftData

struct MissionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var mission: Mission
    
    @State private var newStepTitle: String = ""
    
    var body: some View {
        Form {
            Section(header: Text("Mission Info")) {
                TextField("Title", text: $mission.title)
                TextField("Details (Optional)", text: $mission.details, axis: .vertical)
                    .lineLimit(3...6)
            }
            
            Section(header: Text("Checklist (Steps)")) {
                if let steps = mission.steps?.sorted(by: { $0.order < $1.order }) {
                    ForEach(steps) { step in
                        HStack {
                            Image(systemName: step.isCompleted ? "checkmark.square.fill" : "square")
                                .foregroundStyle(step.isCompleted ? .green : .gray)
                                .onTapGesture {
                                    withAnimation { step.isCompleted.toggle() }
                                }
                            
                            TextField("Step Title", text: Binding(
                                get: { step.title },
                                set: { step.title = $0 }
                            ))
                            .strikethrough(step.isCompleted, color: .gray)
                            .foregroundStyle(step.isCompleted ? .secondary : .primary)
                        }
                    }
                    .onDelete(perform: deleteSteps)
                    .onMove(perform: moveSteps)
                }
                
                HStack {
                    Image(systemName: "plus")
                        .foregroundColor(.accentColor)
                    TextField("Add new step", text: $newStepTitle)
                        .onSubmit {
                            addStep()
                        }
                    Button("Add") {
                        addStep()
                    }
                    .disabled(newStepTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            
            Section(header: Text("Settings")) {
                Picker("Priority", selection: $mission.priority) {
                    Text("Low").tag(Priority.low)
                    Text("Medium").tag(Priority.medium)
                    Text("High").tag(Priority.high)
                }
                
                DatePicker("Due Date", selection: Binding(
                    get: { mission.dueDate ?? Date() },
                    set: { mission.dueDate = $0 }
                ), displayedComponents: .date)
            }
        }
        .navigationTitle("Mission Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func addStep() {
        let trimmed = newStepTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        let currentStepsCount = mission.steps?.count ?? 0
        let step = Step(title: trimmed, order: currentStepsCount)
        step.mission = mission
        modelContext.insert(step)
        
        newStepTitle = ""
        try? modelContext.save()
    }
    
    private func deleteSteps(offsets: IndexSet) {
        guard let steps = mission.steps?.sorted(by: { $0.order < $1.order }) else { return }
        for index in offsets {
            modelContext.delete(steps[index])
        }
        reorderSteps()
    }
    
    private func moveSteps(from source: IndexSet, to destination: Int) {
        guard var steps = mission.steps?.sorted(by: { $0.order < $1.order }) else { return }
        steps.move(fromOffsets: source, toOffset: destination)
        
        for (index, step) in steps.enumerated() {
            step.order = index
        }
        try? modelContext.save()
    }
    
    private func reorderSteps() {
        guard let steps = mission.steps?.sorted(by: { $0.order < $1.order }) else { return }
        for (index, step) in steps.enumerated() {
            step.order = index
        }
        try? modelContext.save()
    }
}
