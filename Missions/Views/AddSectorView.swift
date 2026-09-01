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
                Section(header: Text("Sector Info")) {
                    TextField("Sector Name (e.g. Work, Health)", text: $name)
                    
                    ColorPicker("Theme Color", selection: $color)
                }
                
                Section(header: Text("Icon")) {
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
            .navigationTitle("New Sector")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: saveSector)
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

extension Color {
    func toHex() -> String? {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return nil
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)
        
        if components.count >= 4 {
            a = Float(components[3])
        }
        
        if a != Float(1.0) {
            return String(format: "%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
        } else {
            return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
    }
}
