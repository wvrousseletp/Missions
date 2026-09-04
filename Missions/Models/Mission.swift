import Foundation
import SwiftData

enum Priority: Int, Codable, CaseIterable {
    case low = 0
    case medium = 1
    case high = 2
}

enum Recurrence: String, Codable, CaseIterable {
    case none = "Sem Repetição"
    case daily = "Diariamente"
    case weekdays = "Dias Úteis"
    case customDays = "Dias da Semana"
    case weekly = "Semanalmente"
    case monthly = "Mensalmente"
}

@Model
final class Mission {
    var id: UUID = UUID()
    var title: String
    var details: String
    var dueDate: Date?
    var estimatedMinutes: Int?
    var priorityRaw: Int
    var recurrenceRaw: String
    var selectedDaysRaw: String // ex: "2,4,6" (1=Dom, 2=Seg, 3=Ter, 4=Qua, 5=Qui, 6=Sex, 7=Sab)
    var recurrenceEndDate: Date? // Data limite da repetição (ex: por 2 meses)
    var isAlarmMode: Bool = false // Alerta estilo Despertador em Tela Cheia
    var isWaitingFor: Bool = false // Status Aguardando Resposta de Terceiros
    var waitingPerson: String = "" // Nome do terceiro (ex: Deise, Fornecedor)
    var phase: String = "" // Fase / Marco do Projeto (ex: Fase 1: Planejamento)
    var isCompleted: Bool
    var createdAt: Date
    
    var project: Project?
    
    @Relationship(deleteRule: .cascade, inverse: \Step.mission)
    var steps: [Step]?
    
    var priority: Priority {
        get { Priority(rawValue: priorityRaw) ?? .medium }
        set { priorityRaw = newValue.rawValue }
    }
    
    var recurrence: Recurrence {
        get { Recurrence(rawValue: recurrenceRaw) ?? .none }
        set { recurrenceRaw = newValue.rawValue }
    }
    
    var selectedDays: [Int] {
        get {
            guard !selectedDaysRaw.isEmpty else { return [] }
            return selectedDaysRaw.components(separatedBy: ",").compactMap { Int($0) }
        }
        set {
            selectedDaysRaw = newValue.map { String($0) }.joined(separator: ",")
        }
    }
    
    init(
        title: String,
        details: String = "",
        dueDate: Date? = nil,
        estimatedMinutes: Int? = nil,
        priority: Priority = .medium,
        recurrence: Recurrence = .none,
        selectedDays: [Int] = [],
        recurrenceEndDate: Date? = nil,
        isAlarmMode: Bool = false,
        isWaitingFor: Bool = false,
        waitingPerson: String = "",
        phase: String = ""
    ) {
        self.title = title
        self.details = details
        self.dueDate = dueDate
        self.estimatedMinutes = estimatedMinutes
        self.priorityRaw = priority.rawValue
        self.recurrenceRaw = recurrence.rawValue
        self.selectedDaysRaw = selectedDays.map { String($0) }.joined(separator: ",")
        self.recurrenceEndDate = recurrenceEndDate
        self.isAlarmMode = isAlarmMode
        self.isWaitingFor = isWaitingFor
        self.waitingPerson = waitingPerson
        self.phase = phase
        self.isCompleted = false
        self.createdAt = Date()
    }
    
    // Gerar a próxima repetição com base nos dias da semana e data limite
    func createNextRecurrence() -> Mission? {
        guard recurrence != .none, let currentDueDate = dueDate else { return nil }
        
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "pt_BR")
        var nextDate: Date?
        
        switch recurrence {
        case .none:
            return nil
        case .daily:
            nextDate = calendar.date(byAdding: .day, value: 1, to: currentDueDate)
        case .weekdays:
            var date = calendar.date(byAdding: .day, value: 1, to: currentDueDate) ?? currentDueDate
            while calendar.isDateInWeekend(date) {
                date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
            }
            nextDate = date
        case .customDays:
            guard !selectedDays.isEmpty else { return nil }
            var candidate = calendar.date(byAdding: .day, value: 1, to: currentDueDate) ?? currentDueDate
            for _ in 0..<14 { // Procurar nos próximos 14 dias
                let weekday = calendar.component(.weekday, from: candidate)
                if selectedDays.contains(weekday) {
                    nextDate = candidate
                    break
                }
                candidate = calendar.date(byAdding: .day, value: 1, to: candidate) ?? candidate
            }
        case .weekly:
            nextDate = calendar.date(byAdding: .day, value: 7, to: currentDueDate)
        case .monthly:
            nextDate = calendar.date(byAdding: .month, value: 1, to: currentDueDate)
        }
        
        guard let next = nextDate else { return nil }
        
        // Verificar limite de data (ex: repetição por 2 meses)
        if let endDate = recurrenceEndDate {
            if next > calendar.startOfDay(for: endDate) {
                return nil // Repetição concluída!
            }
        }
        
        let nextMission = Mission(
            title: title,
            details: details,
            dueDate: next,
            estimatedMinutes: estimatedMinutes,
            priority: priority,
            recurrence: recurrence,
            selectedDays: selectedDays,
            recurrenceEndDate: recurrenceEndDate,
            isAlarmMode: isAlarmMode,
            isWaitingFor: isWaitingFor,
            waitingPerson: waitingPerson
        )
        nextMission.project = project
        return nextMission
    }
    
    // Detectar URLs no título e nas anotações
    var detectedURLs: [URL] {
        let fullText = "\(title)\n\(details)"
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else { return [] }
        let matches = detector.matches(in: fullText, options: [], range: NSRange(location: 0, length: fullText.utf16.count))
        return matches.compactMap { $0.url }
    }
    
    // Somatório de custos detectados no checklist
    var totalEstimatedCost: Double {
        guard let steps = steps else { return 0.0 }
        return steps.compactMap { $0.extractedPrice }.reduce(0.0, +)
    }
}
