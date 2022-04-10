import SwiftUI

class SignUpViewModel: ObservableObject {
    @Published var email = ""
    @Published var account = ""
    @Published var nickname = ""
    @Published var password = ""
    @Published var confirmedPassword = ""
}

struct SignUpView: View {
    @EnvironmentObject var model: SignViewModel
    @ObservedObject var signUpViewModel: SignUpViewModel
    @FocusState var isEmailFocused: Bool
    @FocusState var isAccountFocused: Bool
    @FocusState var isNicknameFocused: Bool
    @FocusState var isPasswordFocused: Bool
    @FocusState var isConfirmedPasswordFocused: Bool
    @State var appear = [false, false, false]
    var dismissModal: () -> Void
    @AppStorage("isLogged") var isLogged = false
    @AppStorage("account") var account: String = ""
    @AppStorage("password") var password: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("注册")
                .font(.largeTitle).bold()
                .blendMode(.overlay)
                .slideFadeIn(show: appear[0], offset: 30)

            Text("使用校内邮箱注册以访问论坛的全部内容")
                .font(.headline)
                .foregroundColor(.primary.opacity(0.7))
                .slideFadeIn(show: appear[1], offset: 20)

            form.slideFadeIn(show: appear[2], offset: 10)
        }
        .coordinateSpace(name: "stack")
        .padding(20)
        .padding(.vertical, 20)
        .background(.ultraThinMaterial)
        .backgroundColor(opacity: 0.4)
        .cornerRadius(30)
        .modifier(OutlineModifier(cornerRadius: 30))
        .onAppear { animate() }
    }

    var form: some View {
        Group {
            TextField("", text: $signUpViewModel.email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .placeholder(when: signUpViewModel.email.isEmpty) {
                    Text("校园邮箱")
                        .foregroundColor(.primary)
                        .blendMode(.overlay)
                }
                .customField(icon: "envelope.open.fill")
                .focused($isEmailFocused)

            TextField("", text: $signUpViewModel.account)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .placeholder(when: signUpViewModel.email.isEmpty) {
                    Text("账号")
                        .foregroundColor(.primary)
                        .blendMode(.overlay)
                }
                .customField(icon: "person.crop.circle.fill")
                .focused($isAccountFocused)

            TextField("", text: $signUpViewModel.nickname)
                .textContentType(.username)
                .keyboardType(.default)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .placeholder(when: signUpViewModel.nickname.isEmpty) {
                    Text("昵称（省略则和账号一致）")
                        .foregroundColor(.primary)
                        .blendMode(.overlay)
                }
                .customField(icon: "person.fill")
                .focused($isNicknameFocused)

            SecureField("", text: $signUpViewModel.password)
                .textContentType(.password)
                .placeholder(when: signUpViewModel.password.isEmpty) {
                    Text("密码")
                        .foregroundColor(.primary)
                        .blendMode(.overlay)
                }
                .customField(icon: "key.fill")
                .focused($isPasswordFocused)

            Button {
//                dismissModal()
//                isLogged = true
            } label: {
                AngularButton(title: "注册")
            }

            (Text("注册即代表同意我们的") + Text("**[论坛守则](https://ecnu.im/d/287)**") + Text("及") + Text("**[隐私协议](https://ecnu.im/p/4-privacy)**。"))
                .font(.footnote)
                .foregroundColor(.primary.opacity(0.7))
                .accentColor(.primary.opacity(0.7))

            Divider()

            Text("已经有账号了? **点击登录**")
                .font(.footnote)
                .foregroundColor(.primary.opacity(0.7))
                .accentColor(.primary.opacity(0.7))
                .onTapGesture {
                    withAnimation {
                        model.selectedPanel = .signIn
                    }
                }
        }
    }

    func animate() {
        withAnimation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.8).delay(0.2)) {
            appear[0] = true
        }
        withAnimation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.8).delay(0.4)) {
            appear[1] = true
        }
        withAnimation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.8).delay(0.6)) {
            appear[2] = true
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView(signUpViewModel: SignUpViewModel(), dismissModal: {})
            .environmentObject(SignViewModel())
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
