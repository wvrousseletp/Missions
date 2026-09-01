import SwiftUI
import SwiftData

struct FocusModeView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var mission: Mission
    
    var nextStep: Step? {
        mission.steps?.filter { !$0.isCompleted }.sorted(by: { $0.order < $1.order }).first
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()
                
                VStack(spacing: 16) {
                    Text("CURRENT MISSION")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                        .kerning(1.5)
                    
                    Text(mission.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                if let step = nextStep {
                    VStack(spacing: 24) {
                        Text("NEXT STEP")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                            .kerning(1.5)
                        
                        Text(step.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                step.isCompleted = true
                                checkMissionCompletion()
                            }
                        }) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 80))
                                .foregroundStyle(Color.accentColor)
                                .background(Circle().fill(Color.white).shadow(radius: 10))
                        }
                        .padding(.top, 20)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .padding(.horizontal, 24)
                    
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "flag.checkered.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(.green)
                        
                        Text("Mission Accomplished!")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                }
                
                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.title2)
                    }
                }
            }
        }
    }
    
    private func checkMissionCompletion() {
        let allCompleted = mission.steps?.allSatisfy { $0.isCompleted } ?? false
        if allCompleted {
            withAnimation {
                mission.isCompleted = true
            }
        }
    }
}
