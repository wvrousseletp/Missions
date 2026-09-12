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
                if #available(iOS 16.2, *) {
                    let content = ActivityContent(state: initialContentState, staleDate: nil)
                    _ = try Activity<MissionActivityAttributes>.request(
                        attributes: attributes,
                        content: content,
                        pushType: nil
                    )
                } else {
                    _ = try Activity<MissionActivityAttributes>.request(
                        attributes: attributes,
                        contentState: initialContentState,
                        pushType: nil
                    )
                }
                DispatchQueue.main.async {
                    self.pinnedMissionID = mission.id.uuidString
                }
            } catch {
                print("Erro ao fixar na Dynamic Island: \(error)")
            }
        }
    }
    
    func updatePinnedMission(_ mission: Mission) {
        if #available(iOS 16.1, *) {
            guard isPinned(mission) else { return }
            
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
            
            for activity in Activity<MissionActivityAttributes>.activities {
                if activity.attributes.missionID == mission.id.uuidString {
                    Task {
                        if #available(iOS 16.2, *) {
                            let content = ActivityContent(state: updatedState, staleDate: nil)
                            await activity.update(content)
                        } else {
                            await activity.update(using: updatedState)
                        }
                    }
                }
            }
        }
    }
    
    func unpinCurrentMission() {
        if #available(iOS 16.1, *) {
            for activity in Activity<MissionActivityAttributes>.activities {
                Task {
                    await activity.end(dismissalPolicy: .immediate)
                }
            }
            DispatchQueue.main.async {
                self.pinnedMissionID = nil
            }
        }
    }
    
    func isPinned(_ mission: Mission) -> Bool {
        if #available(iOS 16.1, *) {
            return Activity<MissionActivityAttributes>.activities.contains(where: { $0.attributes.missionID == mission.id.uuidString })
        }
        return pinnedMissionID == mission.id.uuidString
    }
}
