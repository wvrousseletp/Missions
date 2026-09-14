import Foundation
import SwiftData

@Model
final class CustomTaskTemplate {
    var id: UUID = UUID()
    var title: String
    var category: String
    var details: String
    var estimatedMinutes: Int
    var steps: [String]
    var createdAt: Date = Date()
    
    init(title: String, category: String = "Geral", details: String = "", estimatedMinutes: Int = 30, steps: [String] = [], createdAt: Date = Date()) {
        self.id = UUID()
        self.title = title
        self.category = category
        self.details = details
        self.estimatedMinutes = estimatedMinutes
        self.steps = steps
        self.createdAt = createdAt
    }
}

struct CustomTemplateMissionItem: Codable {
    var title: String
    var details: String
    var priorityRaw: Int
    var phase: String
    var steps: [String]
}

@Model
final class CustomProjectTemplate {
    var id: UUID = UUID()
    var name: String
    var iconName: String
    var descriptionText: String
    var category: String
    var missionsDataJSON: String
    var createdAt: Date = Date()
    
    init(name: String, iconName: String = "folder.circle.fill", descriptionText: String = "", category: String = "Personalizado", missionsDataJSON: String = "[]", createdAt: Date = Date()) {
        self.id = UUID()
        self.name = name
        self.iconName = iconName
        self.descriptionText = descriptionText
        self.category = category
        self.missionsDataJSON = missionsDataJSON
        self.createdAt = createdAt
    }
    
    var missionsItems: [CustomTemplateMissionItem] {
        get {
            guard let data = missionsDataJSON.data(using: .utf8),
                  let items = try? JSONDecoder().decode([CustomTemplateMissionItem].self, from: data) else {
                return []
            }
            return items
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let jsonStr = String(data: data, encoding: .utf8) {
                missionsDataJSON = jsonStr
            }
        }
    }
}
