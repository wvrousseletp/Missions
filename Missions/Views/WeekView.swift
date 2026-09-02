import SwiftUI
import SwiftData

struct WeekView: View {
    @AppStorage("isPureBlack") private var isPureBlack: Bool = false
    @Query(sort: \Mission.dueDate) var allMissions: [Mission]
    
    @State private var selectedDate: Date? = nil
    
    var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "pt_BR")
        return cal
    }
    
    // Dias da semana atual
    var currentWeekDays: [Date] {
        let cal = calendar
        let today = cal.startOfDay(for: Date())
        let dayOfWeek = cal.component(.weekday, from: today)
        let firstDayOfWeek = cal.date(byAdding: .day, value: -(dayOfWeek - 1), to: today) ?? today
        
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: firstDayOfWeek) }
    }
    
    // Missões não concluídas com data
    var pendingMissions: [Mission] {
        allMissions.filter { !$0.isCompleted && $0.dueDate != nil }
    }
    
    // Agrupadas por dia
    var missionsByDay: [(Date, [Mission])] {
        let cal = calendar
        var grouped: [Date: [Mission]] = [:]
        
        for mission in pendingMissions {
            if let dueDate = mission.dueDate {
                let startOfDay = cal.startOfDay(for: dueDate)
                if let selected = selectedDate {
                    if cal.isDate(startOfDay, inSameDayAs: selected) {
                        grouped[startOfDay, default: []].append(mission)
                    }
                } else {
                    grouped[startOfDay, default: []].append(mission)
                }
            }
        }
        
        return grouped.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // CALENDÁRIO INTERATIVO HORIZONTAL
                VStack(spacing: 12) {
                    HStack {
                        Text(monthYearString(Date()))
                            .font(.headline)
                            .bold()
                        
                        Spacer()
                        
                        if selectedDate != nil {
                            Button("Ver Toda Semana") {
                                withAnimation {
                                    selectedDate = nil
                                }
                            }
                            .font(.caption)
                            .bold()
                            .foregroundStyle(Color.accentColor)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    HStack(spacing: 8) {
                        ForEach(currentWeekDays, id: \.self) { day in
                            CalendarDayCell(
                                date: day,
                                isSelected: isSelected(day),
                                hasMissions: hasMissionsOnDay(day)
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    if isSelected(day) {
                                        selectedDate = nil
                                    } else {
                                        selectedDate = day
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
                .background(Color.secondary.opacity(0.06))
                
                // LISTA DE CARDS DE MISSÕES
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if missionsByDay.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "calendar.badge.clock")
                                    .font(.system(size: 48))
                                    .foregroundStyle(Color.accentColor.opacity(0.7))
                                Text(selectedDate == nil ? "Sem missões agendadas" : "Nenhuma missão neste dia")
                                    .font(.headline)
                                Text(selectedDate == nil ? "Descanse ou planeje com antecedência!" : "Toque em outro dia no calendário ou adicione um novo lembrete.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                        } else {
                            ForEach(missionsByDay, id: \.0) { date, missions in
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(friendlyDate(date))
                                        .font(.subheadline)
                                        .bold()
                                        .foregroundStyle(.secondary)
                                        .padding(.leading, 4)
                                    
                                    ForEach(missions) { mission in
                                        MissionCard(mission: mission)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }
            }
            .background(Color(uiColor: isPureBlack ? .black : .systemGroupedBackground))
            .preferredColorScheme(isPureBlack ? .dark : nil)
            .environment(\.locale, Locale(identifier: "pt_BR"))
        }
    }
    
    private func isSelected(_ date: Date) -> Bool {
        guard let selected = selectedDate else { return false }
        return calendar.isDate(date, inSameDayAs: selected)
    }
    
    private func hasMissionsOnDay(_ date: Date) -> Bool {
        let cal = calendar
        return pendingMissions.contains { mission in
            if let dueDate = mission.dueDate {
                return cal.isDate(dueDate, inSameDayAs: date)
            }
            return false
        }
    }
    
    private func friendlyDate(_ date: Date) -> String {
        let cal = calendar
        if cal.isDateInToday(date) {
            return "Hoje"
        } else if cal.isDateInTomorrow(date) {
            return "Amanhã"
        } else {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "pt_BR")
            formatter.dateFormat = "EEEE, d 'de' MMMM"
            return formatter.string(from: date).capitalized
        }
    }
    
    private func monthYearString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date).capitalized
    }
}

struct CalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let hasMissions: Bool
    let action: () -> Void
    
    var isToday: Bool {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "pt_BR")
        return cal.isDateInToday(date)
    }
    
    var dayName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).replacingOccurrences(of: ".", with: "").capitalized
    }
    
    var dayNumber: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(dayName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(isSelected ? .white : (isToday ? Color.accentColor : .secondary))
                
                Text(dayNumber)
                    .font(.headline)
                    .fontWeight(isSelected || isToday ? .bold : .regular)
                    .foregroundStyle(isSelected ? .white : (isToday ? Color.accentColor : .primary))
                
                // Pontinho indicador de missões
                Circle()
                    .fill(isSelected ? Color.white : (hasMissions ? Color.accentColor : Color.clear))
                    .frame(width: 4, height: 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : (isToday ? Color.accentColor.opacity(0.12) : Color.clear))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
