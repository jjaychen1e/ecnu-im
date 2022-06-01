//
//  LoadingToast.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/31.
//

import SwiftUI

class LoadingToast {
    private var viewController: UIViewController

    init(hint: String? = nil) {
        viewController = UIHostingController(rootView: LoadingToastView(hint: hint ?? "加载中..."))
        viewController.view.backgroundColor = .clear
    }

    func show() {
        if let window = UIApplication.shared.topController()?.view.window {
            window.addSubview(viewController.view)
            viewController.view.alpha = 0.0
            viewController.view.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            UIView.animate(withDuration: 0.4) { [weak self] in
                if let self = self {
                    self.viewController.view.alpha = 1.0
                }
            }
        }
    }

    func hide() {
        UIView.animate(withDuration: 0.2) { [weak self] in
            if let self = self {
                self.viewController.view.alpha = 0
            }
        } completion: { [weak self] completed in
            if let self = self {
                if completed {
                    self.viewController.view.removeFromSuperview()
                }
            }
        }
    }
}

private struct LoadingToastView: View {
    @State var hint: String? = nil

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Color.primary.opacity(colorScheme == .light ? 0.3 : 0.1)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .edgesIgnoringSafeArea(.all)
            .overlay {
                VStack {
                    ProgressView {
                        Text(hint ?? "加载中...")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(.primary.opacity(0.9))
                    }
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 25)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .allowsHitTesting(false)
    }
}

struct LoadingToastView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingToastView(hint: "登录中...")
    }
}
