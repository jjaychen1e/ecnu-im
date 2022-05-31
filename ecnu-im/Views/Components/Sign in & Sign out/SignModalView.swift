import SwiftUI

extension UIViewController {
    func presentSignView() {
        let model = SignViewModel()
        model.selectedPanel = .signIn
        let hostingVC = UIHostingController(rootView: EnvironmentWrapperView(SignModalView().environmentObject(model), splitVC: nil, nvc: nil, vc: self))
        hostingVC.view.isOpaque = false
        hostingVC.view.backgroundColor = .clear
        hostingVC.modalPresentationStyle = .overCurrentContext
        present(hostingVC, animated: true)
    }
}

struct SignModalView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var model: SignViewModel
    @State var appear = false
    @State var appearBackground = false
    @State var viewState = CGSize.zero
    @ObservedObject private var signInViewModel = SignInViewModel()
    @ObservedObject private var signUpViewModel = SignUpViewModel()

    var drag: some Gesture {
        DragGesture()
            .onChanged { value in
                viewState = value.translation
            }
            .onEnded { value in
                if value.translation.height > 300 {
                    dismissModal()
                } else {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                        viewState = .zero
                    }
                }
            }
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .onTapGesture { dismissModal() }
                .opacity(appear ? 1 : 0)
                .ignoresSafeArea()

            GeometryReader { proxy in
                VStack {
                    Group {
                        switch model.selectedPanel {
                        case .signUp:
                            SignUpView(signUpViewModel: signUpViewModel, dismissModal: { dismissModal() })

                        case .signIn:
                            SignInView(signInViewModel: signInViewModel, dismissModal: { dismissModal() })
                        }
                    }
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                    .rotationEffect(.degrees(viewState.width / 40))
                    .rotation3DEffect(.degrees(viewState.height / 20), axis: (x: 1, y: 0, z: 0), perspective: 1)
                    .shadow(color: Color("Shadow").opacity(0.2), radius: 30, x: 0, y: 30)
                    .offset(x: viewState.width, y: viewState.height)
                    .gesture(drag)
                    .offset(y: appear ? 0 : proxy.size.height)
                }
            }
            .padding(20)
            .background(
                Image("Blob 1")
                    .opacity(appearBackground ? 1 : 0)
                    .offset(y: appearBackground ? -10 : 0)
                    .blur(radius: 40)
                    //                        .blur(radius: appearBackground ? 0 : 40)
                    .hueRotation(.degrees(viewState.width / 5))
                    .allowsHitTesting(false)
                    .accessibility(hidden: true)
            )
            .frame(maxWidth: 600, maxHeight: .infinity, alignment: .center)

            Button {
                dismissModal()
            } label: {
                CloseButton()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding()
            .offset(y: appear ? 0 : -100)
            .opacity(appear ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring()) {
                appear = true
            }
            withAnimation(.easeOut(duration: 2)) {
                appearBackground = true
            }
        }
        .onDisappear {
            withAnimation(.spring()) {
                appear = false
            }
            withAnimation(.easeOut(duration: 1)) {
                appearBackground = true
            }
        }
        .onChange(of: model.dismissModal) { _ in
            dismissModal()
        }
        .accessibilityAddTraits(.isModal)
    }
}

struct SignModalView_Previews: PreviewProvider {
    static var previews: some View {
        let model = SignViewModel()
        model.selectedPanel = .signIn
        return SignModalView()
            .environmentObject(model)
    }
}

extension SignModalView {
    func dismissModal() {
        withAnimation {
            appear = false
            appearBackground = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
        }
    }
}
