import SwiftUI
import SwiftData

struct AddSectorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var iconName: String = "briefcase.fill"
    @State private var color: Color = .blue
    
    let icons = ["briefcase.fill", "dollarsign.circle.fill", "heart.fill", "book.fill", "graduationcap.fill", "cart.fill", "house.fill", "car.fill", "airplane", "gamecontroller.fill"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Informações do Setor")) {
                    TextField("Nome do Setor (ex: Trabalho, Saúde)", text: $name)
                    
                    ColorPicker("Cor do Tema", selection: $color)
                }
                
                Section(header: Text("Ícone")) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 16) {
                        ForEach(icons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title)
                                .frame(width: 44, height: 44)
                                .foregroundStyle(iconName == icon ? .white : .primary)
                                .background(iconName == icon ? color : Color.clear)
                                .clipShape(Circle())
                                .onTapGesture {
                                    iconName = icon
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Novo Setor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar", action: saveSector)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private func saveSector() {
        let hexString = color.toHex() ?? "#007AFF"
        let newSector = Sector(name: name, iconName: iconName, colorHex: hexString, order: 0)
        modelContext.insert(newSector)
        try? modelContext.save()
        dismiss()
    }
}
