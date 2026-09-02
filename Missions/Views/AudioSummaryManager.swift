import Foundation
import AVFoundation

final class AudioSummaryManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    static let shared = AudioSummaryManager()
    
    @Published var isSpeaking: Bool = false
    private let synthesizer = AVSpeechSynthesizer()
    
    override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    func speakSummary(missions: [Mission], totalMins: Int) {
        if isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            isSpeaking = false
            return
        }
        
        let count = missions.count
        var text = ""
        
        if count == 0 {
            text = "Bom dia! Você não tem nenhuma missão agendada para hoje. Aproveite o dia para descansar ou planejar seus próximos objetivos!"
        } else {
            text = "Bom dia! Você tem \(count) \(count == 1 ? "missão agendada" : "missões agendadas") para hoje."
            if totalMins > 0 {
                let hours = totalMins / 60
                let mins = totalMins % 60
                let timeStr = hours > 0 ? "\(hours) horas e \(mins) minutos" : "\(mins) minutos"
                text += " A carga horária estimada é de \(timeStr)."
            }
            if let first = missions.first {
                text += " Sua primeira missão prioritária é: \(first.title)."
            }
            text += " Tenha um excelente dia de foco e produtividade!"
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "pt-BR")
        utterance.rate = 0.52
        
        isSpeaking = true
        synthesizer.speak(utterance)
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
}
