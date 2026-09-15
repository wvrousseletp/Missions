import SwiftUI
import Combine

class FABManager: ObservableObject {
    static let shared = FABManager()
    
    @Published var customAction: (() -> Void)? = nil
    private var currentActionID: UUID? = nil
    
    @discardableResult
    func setAction(_ action: @escaping () -> Void) -> UUID {
        let id = UUID()
        self.currentActionID = id
        self.customAction = action
        return id
    }
    
    func removeAction(id: UUID) {
        if self.currentActionID == id {
            self.currentActionID = nil
            self.customAction = nil
        }
    }
}
