import Foundation
import ActivityKit
import SwiftUI
import Combine

struct MissionActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var missionTitle: String
        var sectorName: String
        var sectorIcon: String
        var isCompleted: Bool
        var progress: Double
        var stepsCountText: String
    }
    
    var missionID: String
}

class DynamicIslandManager: ObservableObject {
    static let shared = DynamicIslandManager()
    
    @Published var pinnedMissionID: String? = nil
    private var currentActivity: Any? = nil
    
    private init() {}
    
    func togglePin(for mission: Mission) {
        if isPinned(mission) {
            unpinCurrentMission()
        } else {
            pinMission(mission)
        }
    }
    
    func pinMission(_ mission: Mission) {
        if #available(iOS 16.1, *) {
            guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
            
            unpinCurrentMission()
            
            let steps = mission.steps ?? []
            let completedSteps = steps.filter { $0.isCompleted }.count
            let totalSteps = steps.count
            let prog = totalSteps > 0 ? Double(completedSteps) / Double(totalSteps) : 0.0
            
            let initialContentState = MissionActivityAttributes.ContentState(
                missionTitle: mission.title,
                sectorName: mission.project?.sector?.name ?? "Geral",
                sectorIcon: mission.project?.sector?.iconName ?? "target",
                isCompleted: mission.isCompleted,
                progress: prog,
                stepsCountText: totalSteps > 0 ? "\(completedSteps)/\(totalSteps) etapas" : "Em Foco"
            )
            
            let attributes = MissionActivityAttributes(missionID: mission.id.uuidString)
            
            do {
                let activity = try Activity<MissionActivityAttributes>.request(
                    attributes: attributes,
                    contentState: initialContentState,
                    pushType: nil
                )
                self.currentActivity = activity
                self.pinnedMissionID = mission.id.uuidString
            } catch {
                print("Erro ao fixar na Dynamic Island: \(error)")
            }
        }
    }
    
    func updatePinnedMission(_ mission: Mission) {
        if #available(iOS 16.1, *) {
            guard isPinned(mission), let activity = currentActivity as? Activity<MissionActivityAttributes> else { return }
            
            let steps = mission.steps ?? []
            let completedSteps = steps.filter { $0.isCompleted }.count
            let totalSteps = steps.count
            let prog = totalSteps > 0 ? Double(completedSteps) / Double(totalSteps) : 0.0
            
            let updatedState = MissionActivityAttributes.ContentState(
                missionTitle: mission.title,
                sectorName: mission.project?.sector?.name ?? "Geral",
                sectorIcon: mission.project?.sector?.iconName ?? "target",
                isCompleted: mission.isCompleted,
                progress: prog,
                stepsCountText: totalSteps > 0 ? "\(completedSteps)/\(totalSteps) etapas" : "Em Foco"
            )
            
            Task {
                await activity.update(using: updatedState)
            }
        }
    }
    
    func unpinCurrentMission() {
        if #available(iOS 16.1, *) {
            if let activity = currentActivity as? Activity<MissionActivityAttributes> {
                Task {
                    await activity.end(dismissalPolicy: .immediate)
                }
            }
            self.currentActivity = nil
            self.pinnedMissionID = nil
        }
    }
    
    func isPinned(_ mission: Mission) -> Bool {
        return pinnedMissionID == mission.id.uuidString
    }
}
