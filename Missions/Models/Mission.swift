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
    
    init(title: String, details: String = "", dueDate: Date? = nil, estimatedMinutes: Int? = nil, priority: Priority = .medium, recurrence: Recurrence = .none) {
        self.title = title
        self.details = details
        self.dueDate = dueDate
        self.estimatedMinutes = estimatedMinutes
        self.priorityRaw = priority.rawValue
        self.recurrenceRaw = recurrence.rawValue
        self.isCompleted = false
        self.createdAt = Date()
    }
    
    // Função para gerar a próxima repetição automaticamente
    func createNextRecurrence() -> Mission? {
        guard recurrence != .none, let currentDueDate = dueDate else { return nil }
        
        let calendar = Calendar.current
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
        case .weekly:
            nextDate = calendar.date(byAdding: .day, value: 7, to: currentDueDate)
        case .monthly:
            nextDate = calendar.date(byAdding: .month, value: 1, to: currentDueDate)
        }
        
        guard let next = nextDate else { return nil }
        
        let nextMission = Mission(
            title: title,
            details: details,
            dueDate: next,
            estimatedMinutes: estimatedMinutes,
            priority: priority,
            recurrence: recurrence
        )
        nextMission.project = project
        return nextMission
    }
    
    // Detectar URLs nas anotações
    var detectedURLs: [URL] {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else { return [] }
        let matches = detector.matches(in: details, options: [], range: NSRange(location: 0, length: details.utf16.count))
        return matches.compactMap { $0.url }
    }
}
