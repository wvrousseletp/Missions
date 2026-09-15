import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("isPureBlack") private var isPureBlack: Bool = false
    @State private var selectedTab: Int = 0
    @State private var showingQuickCapture: Bool = false
    @State private var showingAddSector: Bool = false
    
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var fabManager = FABManager.shared
    @Query var allMissions: [Mission]
    @State private var activeAlarmMission: Mission? = nil
    
    let tabs = [
        (title: "Hoje", icon: "sun.max.fill"),
        (title: "Semana", icon: "calendar"),
        (title: "Setores", icon: "square.grid.2x2.fill"),
        (title: "Backlog", icon: "tray.full.fill")
    ]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // CONTEÚDO DAS ABAS (Sem TabView paging para permitir gestos de sub-páginas no conteúdo)
            Group {
                switch selectedTab {
                case 0:
                    TodayView()
                case 1:
                    WeekView()
                case 2:
                    SectorsView()
                case 3:
                    BacklogView()
                default:
                    TodayView()
                }
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 75)
            }
            .ignoresSafeArea(.all, edges: .bottom)
            
            // BOTÃO FLUTUANTE `+` LOGO ACIMA DO MENU
            HStack {
                Spacer()
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    if let customAction = fabManager.customAction {
                        customAction()
                    } else if selectedTab == 2 {
                        showingAddSector = true
                    } else {
                        showingQuickCapture = true
                    }
                }) {
                    Image(systemName: "plus")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .background(
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: Color.accentColor.opacity(0.45), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 72)
            
            // DOCK BAR INFERIOR DE LARGURA COMPLETA (SEM LINHA SUPERIOR) + DESLIZE DE ABAS NO MENU
            HStack(alignment: .center, spacing: 0) {
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
                    
                    if index < tabs.count - 1 {
                        Spacer(minLength: 0)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 12)
            .background(
                Rectangle()
                    .fill(isPureBlack ? Color(white: 0.08) : Color(UIColor.systemBackground))
                    .ignoresSafeArea(.all, edges: .bottom)
            )
            .gesture(
                DragGesture(minimumDistance: 25, coordinateSpace: .local)
                    .onEnded { value in
                        let horizontalAmount = value.translation.width
                        let verticalAmount = value.translation.height
                        
                        // Garante que é um deslize horizontal exclusivo em cima do menu
                        if abs(horizontalAmount) > abs(verticalAmount) {
                            if horizontalAmount < -30 {
                                // Deslizar para a esquerda -> Próxima Aba Principal
                                if selectedTab < tabs.count - 1 {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                        selectedTab += 1
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    }
                                }
                            } else if horizontalAmount > 30 {
                                // Deslizar para a direita -> Aba Principal Anterior
                                if selectedTab > 0 {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                        selectedTab -= 1
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    }
                                }
                            }
                        }
                    }
            )
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .preferredColorScheme(isPureBlack ? .dark : nil)
        .dismissKeyboardOnScroll()
        .sheet(isPresented: $showingQuickCapture) {
            QuickCaptureView()
                .preferredColorScheme(isPureBlack ? .dark : nil)
        }
        .sheet(isPresented: $showingAddSector) {
            AddSectorView()
                .preferredColorScheme(isPureBlack ? .dark : nil)
        }
        .onChange(of: notificationManager.activeAlarmMissionID) { newValue in
            if let id = newValue, let foundMission = allMissions.first(where: { $0.id == id }) {
                activeAlarmMission = foundMission
            }
        }
        .fullScreenCover(item: $activeAlarmMission) { mission in
            AlarmAlertView(mission: mission)
        }
    }
    
    @Namespace private var tabNamespace
}

#Preview {
    ContentView()
}
