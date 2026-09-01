import SwiftUI
import SwiftData

struct FocusModeView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var mission: Mission
    
    // Timer state
    @State private var timeRemaining: Int = 25 * 60 // 25 minutos
    @State private var isTimerRunning = false
    @State private var timer: Timer? = nil
    
    var nextStep: Step? {
        mission.steps?.filter { !$0.isCompleted }.sorted(by: { $0.order < $1.order }).first
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()
                
                VStack(spacing: 16) {
                    Text("MISSÃO ATUAL")
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
                        Text("PRÓXIMA ETAPA")
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
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
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
                        
                        Text("Missão Cumprida!")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                }
                
                Spacer()
                
                // POMODORO TIMER
                VStack(spacing: 12) {
                    Text(timeString(time: timeRemaining))
                        .font(.system(size: 44, weight: .thin, design: .monospaced))
                    
                    HStack(spacing: 24) {
                        Button(action: toggleTimer) {
                            Image(systemName: isTimerRunning ? "pause.circle.fill" : "play.circle.fill")
                                .font(.title)
                                .foregroundStyle(isTimerRunning ? .orange : .green)
                        }
                        Button(action: resetTimer) {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                                .font(.title)
                                .foregroundStyle(.gray)
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .sensoryFeedback(.success, trigger: mission.isCompleted)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        stopTimer()
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.title2)
                    }
                }
            }
            .onDisappear {
                stopTimer()
            }
        }
    }
    
    private func checkMissionCompletion() {
        let allCompleted = mission.steps?.allSatisfy { $0.isCompleted } ?? false
        if allCompleted {
            withAnimation {
                mission.isCompleted = true
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }
    
    // MARK: - Timer Logic
    private func toggleTimer() {
        if isTimerRunning {
            stopTimer()
        } else {
            startTimer()
        }
    }
    
    private func startTimer() {
        isTimerRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                stopTimer()
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
            }
        }
    }
    
    private func stopTimer() {
        isTimerRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    private func resetTimer() {
        stopTimer()
        timeRemaining = 25 * 60
    }
    
    private func timeString(time: Int) -> String {
        let minutes = time / 60
        let seconds = time % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
