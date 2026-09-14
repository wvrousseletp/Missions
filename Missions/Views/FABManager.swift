import SwiftUI
import Combine

class FABManager: ObservableObject {
    static let shared = FABManager()
    
    @Published var customAction: (() -> Void)? = nil
}
