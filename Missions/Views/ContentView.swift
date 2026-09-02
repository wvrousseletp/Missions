import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab: Int = 0
    @State private var showingQuickCapture: Bool = false
    @State private var showingAddSector: Bool = false
    
    let tabs = [
        (title: "Hoje", icon: "sun.max.fill"),
        (title: "Semana", icon: "calendar"),
        (title: "Setores", icon: "square.grid.2x2.fill"),
        (title: "Backlog", icon: "tray.full.fill")
    ]
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                // ABAS NAVEGÁVEIS POR DESLIZAMENTO (SWIPE)
                TabView(selection: $selectedTab) {
                    TodayView()
                        .tag(0)
                    
                    WeekView()
                        .tag(1)
                    
                    SectorsView()
                        .tag(2)
                    
                    BacklogView()
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // BARRA INFERIOR DE NAVEGAÇÃO PERSONALIZADA
                HStack {
                    ForEach(0..<tabs.count, id: \.self) { index in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = index
                            }
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: tabs[index].icon)
                                    .font(.title3)
                                Text(tabs[index].title)
                                    .font(.caption2)
                                    .fontWeight(selectedTab == index ? .bold : .regular)
                            }
                            .foregroundStyle(selectedTab == index ? Color.accentColor : Color.secondary)
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.top, 10)
                .padding(.bottom, 24)
                .background(.thinMaterial)
            }
            
            // BOTÃO FLUTUANTE UNIFICADO NO CANTO INFERIOR DIREITO
            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                if selectedTab == 2 {
                    showingAddSector = true
                } else {
                    showingQuickCapture = true
                }
            }) {
                Image(systemName: "plus")
                    .font(.title.bold())
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.accentColor.gradient)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 80) // Fica posicionado logo acima da barra inferior
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .sheet(isPresented: $showingQuickCapture) {
            QuickCaptureView()
        }
        .sheet(isPresented: $showingAddSector) {
            AddSectorView()
        }
    }
}

#Preview {
    ContentView()
}
