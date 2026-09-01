import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "sun.max.fill")
                }
            
            WeekView()
                .tabItem {
                    Label("Week", systemImage: "calendar")
                }
            
            SectorsView()
                .tabItem {
                    Label("Sectors", systemImage: "square.grid.2x2.fill")
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
