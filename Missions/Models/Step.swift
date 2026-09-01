import Foundation
import SwiftData

@Model
final class Step {
    var id: UUID = UUID()
    var title: String
    var isCompleted: Bool
    var order: Int
    
    var mission: Mission?
    
    init(title: String, isCompleted: Bool = false, order: Int = 0) {
        self.title = title
        self.isCompleted = isCompleted
        self.order = order
    }
}
