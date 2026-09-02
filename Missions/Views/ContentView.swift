import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("isPureBlack") private var isPureBlack: Bool = false
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
        ZStack(alignment: .bottom) {
            // CONTEÚDO DAS ABAS NAVEGÁVEIS POR DESLIZAMENTO
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
            .ignoresSafeArea(.all, edges: .bottom)
            
            // DOCK BAR FLUTUANTE PREMIUM + BOTÃO FLUTUANTE (FAB)
            HStack(alignment: .center, spacing: 0) {
                // ABAS DE NAVEGAÇÃO COM PILL ANIMADO
                HStack(spacing: 4) {
                    ForEach(0..<tabs.count, id: \.self) { index in
                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                selectedTab = index
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: tabs[index].icon)
                                    .font(.system(size: 16, weight: selectedTab == index ? .bold : .medium))
                                
                                if selectedTab == index {
                                    Text(tabs[index].title)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .foregroundStyle(selectedTab == index ? .white : .secondary)
                            .padding(.horizontal, selectedTab == index ? 14 : 10)
                            .padding(.vertical, 10)
                            .background(
                                ZStack {
                                    if selectedTab == index {
                                        Capsule()
                                            .fill(Color.accentColor.gradient)
                                            .matchedGeometryEffect(id: "activeTabPill", in: tabNamespace)
                                            .shadow(color: Color.accentColor.opacity(0.4), radius: 6, x: 0, y: 3)
                                    }
                                }
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(6)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 6)
                
                Spacer()
                
                // BOTÃO FLUTUANTE `+` PREMIUM
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    if selectedTab == 2 {
                        showingAddSector = true
                    } else {
                        showingQuickCapture = true
                    }
                }) {
                    Image(systemName: "plus")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                        .frame(width: 48, height: 48)
                        .background(
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(color: Color.accentColor.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .preferredColorScheme(isPureBlack ? .dark : nil)
        .sheet(isPresented: $showingQuickCapture) {
            QuickCaptureView()
                .preferredColorScheme(isPureBlack ? .dark : nil)
        }
        .sheet(isPresented: $showingAddSector) {
            AddSectorView()
                .preferredColorScheme(isPureBlack ? .dark : nil)
        }
    }
    
    @Namespace private var tabNamespace
}

#Preview {
    ContentView()
}
