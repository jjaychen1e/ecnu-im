import Combine
import SwiftUI

class SignViewModel: ObservableObject {
    @Published var selectedPanel: LoginPanel = .signUp
    @Published var dismissModal: Bool = false
}

enum LoginPanel: String {
    case signUp
    case signIn
}
