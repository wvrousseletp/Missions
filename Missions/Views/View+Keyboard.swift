import SwiftUI
import UIKit

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // Suporte nativo do iOS para fechar o teclado ao rolar ou tocar na área externa sem bloquear os menus de Copiar/Colar
    func dismissKeyboardOnScroll() -> some View {
        if #available(iOS 16.0, *) {
            return self.scrollDismissesKeyboard(.immediately)
        } else {
            return self
        }
    }
}
