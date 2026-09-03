import SwiftUI
import SwiftData

struct AlarmAlertView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var mission: Mission
    
    @State private var isPulsing: Bool = false
    @State private var showingFocusMode: Bool = false
    
    var timeString: String {
        guard let date = mission.dueDate else { return "--:--" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    var body: some View {
        ZStack {
            // FUNDO ESCURO PROFUNDO COM DEGRADÊ DE ALERTA
            LinearGradient(
                colors: [Color.black, Color.red.opacity(0.4), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 28) {
                Spacer()
                
                // ÍCONE ANIMADO DE DESPERTADOR PULSANTE
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 140, height: 140)
                        .scaleEffect(isPulsing ? 1.25 : 0.95)
                        .opacity(isPulsing ? 0.3 : 0.8)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isPulsing)
                    
                    Circle()
                        .fill(Color.red.gradient)
                        .frame(width: 90, height: 90)
                        .shadow(color: .red.opacity(0.6), radius: 16, x: 0, y: 0)
                    
                    Image(systemName: "bell.badge.wave.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.white)
                }
                .padding(.bottom, 10)
                
                // HORA DA MISSAO EM TAMANHO GIGANTE DE DESPERTADOR
                VStack(spacing: 4) {
                    Text(timeString)
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("DESPERTADOR DE MISSÃO")
                        .font(.caption)
                        .fontWeight(.heavy)
                        .kerning(2.0)
                        .foregroundStyle(.red)
                }
                
                // TÍTULO DA MISSAO E SETOR/PROJETO
                VStack(spacing: 10) {
                    Text(mission.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    
                    if let project = mission.project, let sector = project.sector {
                        HStack(spacing: 6) {
                            Image(systemName: sector.iconName)
                            Text("\(sector.name) • \(project.name)")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.15))
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                    }
                    
                    if !mission.details.isEmpty {
                        Text(mission.details)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .padding(.horizontal, 32)
                            .padding(.top, 4)
                    }
                }
                
                Spacer()
                
                // BOTOES DE AÇÃO EM TELA CHEIA (INICIAR FOCO / SONECA / CONCLUIR)
                VStack(spacing: 14) {
                    Button(action: {
                        showingFocusMode = true
                    }) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                                .font(.title2)
                            Text("Iniciar Modo Foco Agora")
                                .font(.headline)
                                .bold()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentColor.gradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: Color.accentColor.opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                    
                    HStack(spacing: 12) {
                        Button(action: snoozeMission) {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                Text("Soneca (+10m)")
                                    .bold()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.15))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                        
                        Button(action: completeMission) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Concluir")
                                    .bold()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.green.gradient)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .fullScreenCover(isPresented: $showingFocusMode) {
            FocusModeView(mission: mission)
        }
        .onAppear {
            isPulsing = true
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
    }
    
    private func snoozeMission() {
        let tenMinsLater = Calendar.current.date(byAdding: .minute, value: 10, to: Date()) ?? Date()
        mission.dueDate = tenMinsLater
        try? modelContext.save()
        NotificationManager.shared.scheduleNotification(for: mission)
        dismiss()
    }
    
    private func completeMission() {
        mission.isCompleted = true
        NotificationManager.shared.cancelNotification(for: mission)
        if let next = mission.createNextRecurrence() {
            modelContext.insert(next)
            NotificationManager.shared.scheduleNotification(for: next)
        }
        try? modelContext.save()
        dismiss()
    }
}
