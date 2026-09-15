import Foundation

let path = "Missions/Views/ContentView.swift"
var content = try String(contentsOfFile: path)

let oldBackground = """
            .background(
                ZStack {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea(.all, edges: .bottom)
                    
                    VStack {
                        Divider()
                        Spacer()
                    }
                }
            )
"""

let newBackground = """
            .background(
                Rectangle()
                    .fill(isPureBlack ? Color(white: 0.08) : Color(UIColor.systemBackground))
                    .ignoresSafeArea(.all, edges: .bottom)
            )
            .overlay(
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color.gray.opacity(isPureBlack ? 0.3 : 0.15)),
                alignment: .top
            )
"""

if content.contains(oldBackground) {
    content = content.replacingOccurrences(of: oldBackground, with: newBackground)
    try content.write(toFile: path, atomically: true, encoding: .utf8)
    print("Patched successfully")
} else {
    print("Could not find old background string")
}
