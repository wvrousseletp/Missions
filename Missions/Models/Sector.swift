import Foundation
import SwiftData
import SwiftUI

@Model
final class Sector {
    var id: UUID = UUID()
    var name: String
    var iconName: String // SF Symbol name
    var colorHex: String
    var order: Int
    var targetGoal: String? = nil
    
    @Relationship(deleteRule: .cascade, inverse: \Project.sector)
    var projects: [Project]?
    
    init(name: String, iconName: String, colorHex: String, order: Int, targetGoal: String? = nil) {
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.order = order
        self.targetGoal = targetGoal
    }
}
