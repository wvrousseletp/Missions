import Foundation
import SwiftData

@Model
final class Step {
    var id: UUID = UUID()
    var title: String
    var isCompleted: Bool
    var order: Int
    var isWaitingFor: Bool = false
    var waitingPerson: String = ""
    
    var mission: Mission?
    
    init(title: String, isCompleted: Bool = false, order: Int = 0, isWaitingFor: Bool = false, waitingPerson: String = "") {
        self.title = title
        self.isCompleted = isCompleted
        self.order = order
        self.isWaitingFor = isWaitingFor
        self.waitingPerson = waitingPerson
    }
    
    // Detectar URLs automaticamente em etapas/checkboxes (ex: links de localização do Google Maps)
    var detectedURLs: [URL] {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else { return [] }
        let matches = detector.matches(in: title, options: [], range: NSRange(location: 0, length: title.utf16.count))
        return matches.compactMap { $0.url }
    }
    
    // Detectar valores financeiros nas etapas
    var extractedPrice: Double? {
        let pattern = #"(?:R\$\s*)?(\d+[\.\,]\d{2})"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        let matches = regex.matches(in: title, options: [], range: NSRange(location: 0, length: title.utf16.count))
        
        for match in matches {
            if let range = Range(match.range(at: 1), in: title) {
                let strVal = String(title[range]).replacingOccurrences(of: ",", with: ".")
                if let val = Double(strVal), val > 0 {
                    return val
                }
            }
        }
        return nil
    }
}
