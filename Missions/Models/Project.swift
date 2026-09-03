import Foundation
import SwiftData

enum ProjectStatus: String, CaseIterable, Codable {
    case active = "Em Andamento"
    case paused = "Em Pausa"
    case completed = "Concluído"
}

@Model
final class Project {
    var id: UUID = UUID()
    var name: String
    var projectDescription: String
    var createdAt: Date
    var isStarred: Bool = false
    var statusRaw: String = "active"
    var colorHex: String? = nil
    var startDate: Date? = nil
    var targetDate: Date? = nil
    
    var sector: Sector?
    
    @Relationship(deleteRule: .cascade, inverse: \Mission.project)
    var missions: [Mission]?
    
    var status: ProjectStatus {
        get { ProjectStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }
    
    var completedMissionsCount: Int {
        missions?.filter { $0.isCompleted }.count ?? 0
    }
    
    var totalMissionsCount: Int {
        missions?.count ?? 0
    }
    
    var progress: Double {
        totalMissionsCount > 0 ? Double(completedMissionsCount) / Double(totalMissionsCount) : 0.0
    }
    
    init(
        name: String,
        projectDescription: String = "",
        createdAt: Date = Date(),
        isStarred: Bool = false,
        status: ProjectStatus = .active,
        colorHex: String? = nil,
        startDate: Date? = nil,
        targetDate: Date? = nil
    ) {
        self.name = name
        self.projectDescription = projectDescription
        self.createdAt = createdAt
        self.isStarred = isStarred
        self.statusRaw = status.rawValue
        self.colorHex = colorHex
        self.startDate = startDate
        self.targetDate = targetDate
    }
}
