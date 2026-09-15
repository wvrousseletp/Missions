import Foundation

let path = "Missions/Views/TodayView.swift"
var content = try String(contentsOfFile: path)

// Regex para remover propriedades desnecessárias (greetingText, cognitiveFreedomText)
// Vamos usar replace direto pois eu sei o conteúdo
let lines = content.components(separatedBy: .newlines)
var newLines: [String] = []

var skipMode = false
for line in lines {
    if line.contains("var greetingText: String {") || 
       line.contains("var cognitiveFreedomText: String {") || 
       line.contains("// BANNER DE SAUDAÇÃO & LIBERDADE MENTAL COGNITIVA") {
        skipMode = true
    }
    
    if !skipMode {
        newLines.append(line)
    }
    
    // O fechamento de block das variáveis ou do HStack de banner
    if skipMode {
        if line.trimmingCharacters(in: .whitespaces) == "}" {
            // Se for o fechamento da var greeting ou cognitive, ainda estamos no modo skip, pois a chave fecha.
            // Para ser robusto, vou ignorar manualmente:
            // Mas var greeting tem blocos aninhados (if).
            // Melhor: vou usar regex ou replacement exato
        }
    }
}
// Abandonei a ideia simplista de parsear swift manualmente linha a linha assim.
