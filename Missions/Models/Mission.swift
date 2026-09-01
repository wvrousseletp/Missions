import Foundation
import SwiftData

enum Priority: Int, Codable, CaseIterable {
    case low = 0
    case medium = 1
    case high = 2
}

enum Recurrence: String, Codable, CaseIterable {
    case none = "None"
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
}

@Model
final class Mission {
    var id: UUID = UUID()
    var title: String
    var details: String
    var dueDate: Date?
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
    
    init(title: String, details: String = "", dueDate: Date? = nil, priority: Priority = .medium, recurrence: Recurrence = .none) {
        self.title = title
        self.details = details
        self.dueDate = dueDate
        self.priorityRaw = priority.rawValue
        self.recurrenceRaw = recurrence.rawValue
        self.isCompleted = false
        self.createdAt = Date()
    }
}
