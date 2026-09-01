import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Hoje", systemImage: "sun.max.fill")
                }
            
            WeekView()
                .tabItem {
                    Label("Semana", systemImage: "calendar")
                }
            
            SectorsView()
                .tabItem {
                    Label("Setores", systemImage: "square.grid.2x2.fill")
                }
            
            BacklogView()
                .tabItem {
                    Label("Backlog", systemImage: "tray.full.fill")
                }
        }
        .tint(.accentColor)
    }
}

#Preview {
    ContentView()
}
