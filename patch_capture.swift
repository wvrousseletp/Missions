import Foundation

let path = "Missions/Views/QuickCaptureView.swift"
var content = try String(contentsOfFile: path)

// Add @State for isRoutine
if !content.contains("var isRoutine = false") {
    content = content.replacingOccurrences(of: "@State private var title = \"\"", with: "@State private var title = \"\"\n    @State private var isRoutine = false")
}

// Add Toggle in Section("Detalhes Principais")
if !content.contains("Rotina/Hábito Diário") {
    content = content.replacingOccurrences(of: "TextField(\"Notas adicionais (opcional)\", text: $details, axis: .vertical)", with: "TextField(\"Notas adicionais (opcional)\", text: $details, axis: .vertical)\n                    Toggle(\"Rotina/Hábito Diário\", isOn: $isRoutine)")
}

// Pass isRoutine to Mission init
content = content.replacingOccurrences(of: "isWaitingFor: isWaitingFor,", with: "isWaitingFor: isWaitingFor,\n            waitingPerson: waitingPerson,\n            isRoutine: isRoutine")
content = content.replacingOccurrences(of: "waitingPerson: waitingPerson\n        )", with: ")\n")

try content.write(toFile: path, atomically: true, encoding: .utf8)
