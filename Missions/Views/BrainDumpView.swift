import SwiftUI
import SwiftData

struct BrainDumpView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var dumpText: String = ""
    @State private var scheduleForToday: Bool = true
    @State private var processedCount: Int = 0
    @State private var isSuccess: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.purple.opacity(0.18))
                            .frame(width: 44, height: 44)
                        Text("🧠")
                            .font(.title2)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Descarrego Mental Instantâneo")
                            .font(.headline)
                            .bold()
                        Text("Digite ou dite tudo o que está na sua cabeça (1 por linha)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)
                
                TextEditor(text: $dumpText)
                    .padding(12)
                    .background(Color.secondary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal)
                
                Toggle(isOn: $scheduleForToday) {
                    HStack {
                        Image(systemName: "sun.max.fill")
                            .foregroundStyle(.orange)
                        Text("Agendar itens para Hoje")
                            .font(.subheadline)
                            .bold()
                    }
                }
                .padding(.horizontal)
                
                Button(action: processBrainDump) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .font(.title3)
                        Text("Processar e Liberar Minha Mente")
                            .font(.headline)
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(dumpText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray.gradient : Color.purple.gradient)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Color.purple.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(dumpText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
            .navigationTitle("Descarrego Mental")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancelar") { dismiss() }
            )
            .alert("Mente Limpa! 🧘", isPresented: $isSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("\(processedCount) tarefas foram salvas no app. Sua memória está liberada!")
            }
        }
    }
    
    private func processBrainDump() {
        let lines = dumpText.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        guard !lines.isEmpty else { return }
        
        for line in lines {
            let cleanTitle = line.replacingOccurrences(of: #"^([\-\*\•]|\d+[\.\)])\s+"#, with: "", options: .regularExpression)
            guard !cleanTitle.isEmpty else { continue }
            
            let mission = Mission(
                title: cleanTitle,
                dueDate: scheduleForToday ? Date() : nil,
                priority: .medium
            )
            modelContext.insert(mission)
            NotificationManager.shared.scheduleNotification(for: mission)
        }
        
        try? modelContext.save()
        processedCount = lines.count
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        isSuccess = true
    }
}
