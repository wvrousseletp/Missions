import Foundation
import UserNotifications
import Combine

class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    @Published var activeAlarmMissionID: UUID? = nil
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkAuthorizationStatus()
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound, .criticalAlert]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                if granted {
                    self.scheduleDailyMorningDigest()
                }
            }
        }
    }
    
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func scheduleNotification(for mission: Mission) {
        guard isAuthorized, let dueDate = mission.dueDate, !mission.isCompleted else { return }
        
        // Evitar agendar notificações no passado
        guard dueDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        
        if mission.isAlarmMode {
            content.title = "🚨 DESPERTADOR DE MISSÃO"
            content.body = "⏰ \(mission.title)"
            content.sound = .criticalSoundNamed(UNNotificationSoundName(rawValue: "alarm.wav"), withAudioVolume: 1.0)
            if #available(iOS 15.0, *) {
                content.interruptionLevel = .critical
            }
        } else {
            content.title = "Lembrete de Missão 🎯"
            content.body = mission.title
            content.sound = .default
            if #available(iOS 15.0, *) {
                content.interruptionLevel = .timeSensitive
            }
        }
        
        content.userInfo = [
            "missionID": mission.id.uuidString,
            "isAlarmMode": mission.isAlarmMode
        ]
        
        if let project = mission.project, let sector = project.sector {
            content.subtitle = "\(sector.name) • \(project.name)"
        }
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: mission.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelNotification(for mission: Mission) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [mission.id.uuidString])
    }
    
    func scheduleDailyMorningDigest() {
        let content = UNMutableNotificationContent()
        content.title = "Bom dia! ☀️"
        content.body = "Abra o Missions para planejar e conquistar suas tarefas de hoje!"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 8 // 8:00 AM
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_morning_digest", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // DELEGATE: QUANDO A NOTIFICAÇÃO DISPARA COM O APP ABERTO OU EM SEGUNDO PLANO
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        if let missionIDStr = userInfo["missionID"] as? String, let missionUUID = UUID(uuidString: missionIDStr) {
            DispatchQueue.main.async {
                self.activeAlarmMissionID = missionUUID
            }
        }
        completionHandler([.banner, .sound, .badge, .list])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        if let missionIDStr = userInfo["missionID"] as? String, let missionUUID = UUID(uuidString: missionIDStr) {
            DispatchQueue.main.async {
                self.activeAlarmMissionID = missionUUID
            }
        }
        completionHandler()
    }
}
