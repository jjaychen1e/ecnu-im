import SwiftUI

class SignInViewModel: ObservableObject {
    @Published var account = ""
    @Published var password = ""
}

struct SignInView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var model: SignViewModel
    @ObservedObject var signInViewModel: SignInViewModel
    @FocusState var isEmailFocused: Bool
    @FocusState var isPasswordFocused: Bool
    @State var appear = [false, false, false]
    @State private var logging = false
    var dismissModal: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("登录")
                .font(.largeTitle).bold()
                .blendMode(.overlay)
                .slideFadeIn(show: appear[0], offset: 30)

            Text("使用已认证校内邮箱的账号来访问全部内容")
                .font(.headline)
                .foregroundStyle(.secondary)
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
        .onLoad { animate() }
    }

    var form: some View {
        Group {
            TextField("用户名或邮箱", text: $signInViewModel.account)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .customField(icon: "envelope.open.fill")
                .focused($isEmailFocused)

            SecureField("密码", text: $signInViewModel.password)
                .textContentType(.password)
                .customField(icon: "key.fill")
                .focused($isPasswordFocused)

            Button {
                Task {
                    logging = true
                    if await AppGlobalState.shared.login(account: signInViewModel.account, password: signInViewModel.password) {
                        model.dismissModal.toggle()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            let toast = Toast.default(
                                icon: .emoji("🎉"),
                                title: "登录成功"
                            )
                            toast.show()
                        }
                    } else {
                        let toast = Toast.default(
                            icon: .emoji("❗️"),
                            title: "登录失败",
                            subtitle: "请检查你的账户与密码"
                        )
                        toast.show()
                    }
                    logging = false
                }
            } label: {
                AngularButton(title: "登录")
            }
            .disabled(logging)

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Text("还没有账号? **点击注册**")
                    .font(.footnote)
                    .foregroundColor(.primary.opacity(0.7))
                    .accentColor(.primary.opacity(0.7))
                    .onTapGesture {
                        withAnimation {
                            model.selectedPanel = .signUp
                        }
                    }

                Text("**忘记密码？**")
                    .font(.footnote)
                    .foregroundColor(.primary.opacity(0.7))
                    .accentColor(.primary.opacity(0.7))
                    .onTapGesture {
                        let selectSignUpButtonJS = """
                        document.querySelector('ul  li.item-logIn > button').click();
                        document.querySelector('p.LogInModal-forgotPassword > a').click();
                        """
                        if let url = URL(string: URLService.link(href: "https://ecnu.im/", jsAction: selectSignUpButtonJS).url) {
                            UIApplication.shared.open(url)
                        }
                    }

                Text("**点击此处打开腾讯企业邮箱**")
                    .font(.footnote)
                    .foregroundColor(.primary.opacity(0.7))
                    .accentColor(.primary.opacity(0.7))
                    .onTapGesture {
                        if let url = URL(string: URLService.link(href: "https://exmail.qq.com/").url) {
                            UIApplication.shared.open(url)
                        }
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

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView(signInViewModel: SignInViewModel(), dismissModal: {})
            .environmentObject(SignViewModel())
    }
}
