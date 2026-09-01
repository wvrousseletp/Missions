import Foundation
import SwiftData

@Model
final class Project {
    var id: UUID = UUID()
    var name: String
    var projectDescription: String
    var createdAt: Date
    
    var sector: Sector?
    
    @Relationship(deleteRule: .cascade, inverse: \Mission.project)
    var missions: [Mission]?
    
    init(name: String, projectDescription: String = "", createdAt: Date = Date()) {
        self.name = name
        self.projectDescription = projectDescription
        self.createdAt = createdAt
    }
}
