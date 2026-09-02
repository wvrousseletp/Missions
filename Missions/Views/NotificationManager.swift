import Foundation
import UserNotifications
import Combine

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    
    init() {
        checkAuthorizationStatus()
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
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
        content.title = "Lembrete de Missão 🎯"
        content.body = mission.title
        content.sound = .default
        
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
}
