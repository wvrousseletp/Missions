import Foundation

let path = "Missions/Models/Mission.swift"
var content = try String(contentsOfFile: path)

// add to init parameters
content = content.replacingOccurrences(of: "phase: String = \"\"", with: "phase: String = \"\",\n        isRoutine: Bool = false")

// set self.isRoutine
content = content.replacingOccurrences(of: "self.phase = phase", with: "self.phase = phase\n        self.isRoutine = isRoutine")

// pass isRoutine to createNextRecurrence
content = content.replacingOccurrences(of: "waitingPerson: waitingPerson", with: "waitingPerson: waitingPerson,\n            isRoutine: isRoutine")

try content.write(toFile: path, atomically: true, encoding: .utf8)
print("Patched Mission.swift")
