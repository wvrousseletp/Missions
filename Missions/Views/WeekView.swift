import SwiftUI
import SwiftData

struct WeekView: View {
    @Query(sort: \Mission.dueDate) var allMissions: [Mission]
    
    @State private var selectedDate: Date? = nil
    
    // Dias da semana atual
    var currentWeekDays: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayOfWeek = calendar.component(.weekday, from: today)
        let firstDayOfWeek = calendar.date(byAdding: .day, value: -(dayOfWeek - 1), to: today) ?? today
        
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: firstDayOfWeek) }
    }
    
    // Missões não concluídas com data
    var pendingMissions: [Mission] {
        allMissions.filter { !$0.isCompleted && $0.dueDate != nil }
    }
    
    // Agrupadas por dia
    var missionsByDay: [(Date, [Mission])] {
        let calendar = Calendar.current
        var grouped: [Date: [Mission]] = [:]
        
        for mission in pendingMissions {
            if let dueDate = mission.dueDate {
                let startOfDay = calendar.startOfDay(for: dueDate)
                if let selected = selectedDate {
                    if calendar.isDate(startOfDay, inSameDayAs: selected) {
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
                
                // LISTA DE MISSÕES
                List {
                    if missionsByDay.isEmpty {
                        ContentUnavailableView(
                            selectedDate == nil ? "Sem missões agendadas" : "Nenhuma missão neste dia",
                            systemImage: "calendar.badge.clock",
                            description: Text(selectedDate == nil ? "Descanse ou planeje com antecedência!" : "Toque em outro dia no calendário ou adicione um novo lembrete.")
                        )
                    } else {
                        ForEach(missionsByDay, id: \.0) { date, missions in
                            Section(header: Text(friendlyDate(date)).bold().textCase(nil)) {
                                ForEach(missions) { mission in
                                    MissionRow(mission: mission)
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }
    
    private func isSelected(_ date: Date) -> Bool {
        guard let selected = selectedDate else { return false }
        return Calendar.current.isDate(date, inSameDayAs: selected)
    }
    
    private func hasMissionsOnDay(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return pendingMissions.contains { mission in
            if let dueDate = mission.dueDate {
                return calendar.isDate(dueDate, inSameDayAs: date)
            }
            return false
        }
    }
    
    private func friendlyDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Hoje"
        } else if calendar.isDateInTomorrow(date) {
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
        Calendar.current.isDateInToday(date)
    }
    
    var dayName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).replacingOccurrences(of: ".", with: "").capitalized
    }
    
    var dayNumber: String {
        let formatter = DateFormatter()
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
