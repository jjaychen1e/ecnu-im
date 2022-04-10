import SwiftUI
import UIKit

struct ToastPopover: View {
    @Environment(\.colorScheme) var colorScheme
    @State var icon: Toast.Icon?
    @State var title: String
    @State var subtitle: String? = nil

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            if let icon = icon {
                switch icon {
                case let .image(uiImage, tint):
                    Image(uiImage: uiImage)
                        .resizable()
                        .tint(.init(uiColor: tint))
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 28, height: 28)
                case let .emoji(emoji):
                    Text(emoji)
                        .font(.system(size: 28, weight: .bold))
                }
            }
            VStack(alignment: .center, spacing: 2) {
                Text(title)
                    .lineLimit(1)
                    .font(.system(size: 14, weight: .bold))

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.init(uiColor: .systemGray))
                }
            }
        }
        .padding(.horizontal, 25)
        .padding(.vertical, 10)
        .frame(minWidth: 150, minHeight: 58)
        .background(
            RoundedRectangle(cornerRadius: 100)
                .stroke(.gray.opacity(0.1))
                .background(
                    RoundedRectangle(cornerRadius: 100)
                        .fill(colorScheme == .light ? Color(red: 0.99, green: 0.99, blue: 0.99) : Color(red: 0.13, green: 0.13, blue: 0.13))
                )
        )
        .shadow(color: Color("Shadow").opacity(0.3), radius: 20, x: 0, y: 10)
    }
}

class Toast: Hashable {
    static func == (lhs: Toast, rhs: Toast) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    private let id = UUID()

    static var defaultImageTint: UIColor {
        if #available(iOS 13.0, *) {
            return .label
        } else {
            return .black
        }
    }

    private static var toasts: Set<Toast> = []

    private let config: ToastConfiguration
    private var view: UIView

    enum Icon {
        case image(UIImage, UIColor = defaultImageTint)
        case emoji(String)
    }

    required init(view: UIView, config: ToastConfiguration) {
        self.view = view
        self.config = config
    }

    private var initialTransform: CGAffineTransform {
        return CGAffineTransform(scaleX: 0.9, y: 0.9).translatedBy(x: 0, y: -100)
    }

    /// Creates a new Toast with the default Apple style layout with a title and an optional subtitle.
    /// - Parameters:
    ///   - title: Title which is displayed in the toast view
    ///   - subtitle: Optional subtitle which is displayed in the toast view
    ///   - config: Configuration options
    /// - Returns: A new Toast view with the configured layout
    static func text(
        _ title: String,
        subtitle: String? = nil,
        config: ToastConfiguration = ToastConfiguration()
    ) -> Toast {
        return Self.default(icon: nil, title: title, subtitle: subtitle, config: config)
    }

    /// Creates a new Toast with the default Apple style layout with an icon, title and optional subtitle.
    /// - Parameters:
    ///   - image: Image which is displayed in the toast view
    ///   - imageTint: Tint of the image
    ///   - title: Title which is displayed in the toast view
    ///   - subtitle: Optional subtitle which is displayed in the toast view
    ///   - config: Configuration options
    /// - Returns: A new Toast view with the configured layout
    static func `default`(
        icon: Icon?,
        title: String,
        subtitle: String? = nil,
        config: ToastConfiguration = ToastConfiguration()
    ) -> Toast {
        let view = UIHostingController(rootView: ToastPopover(icon: icon, title: title, subtitle: subtitle)).view!

        return self.init(view: view, config: config)
    }

    /// Show the toast with haptic feedback
    /// - Parameters:
    ///   - type: Haptic feedback type
    ///   - time: Time after which the toast is shown
    func show(haptic type: UINotificationFeedbackGenerator.FeedbackType, after time: TimeInterval = 0) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
        show(after: time)
    }

    /// Show the toast
    /// - Parameter delay: Time after which the toast is shown
    func show(after delay: TimeInterval = 0) {
        config.view?.addSubview(view) ?? UIApplication.shared.topController()?.view.addSubview(view)
        view.backgroundColor = .clear
        view.transform = initialTransform
        view.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
        }

        Self.toasts.forEach { toast in
            toast.close(after: 0, mode: .opacity)
        }

        Self.toasts.insert(self)

        UIView.animate(withDuration: config.animationTime, delay: delay, options: [.curveEaseOut, .allowUserInteraction]) {
            self.view.transform = .identity
        } completion: { [weak self] _ in
            if let self = self {
                if self.config.autoHide {
                    self.close(after: self.config.displayTime)
                }
            }
        }
    }

    enum ToastCloseAnimationType {
        case transform
        case opacity
    }

    /// Close the toast
    /// - Parameters:
    ///   - time: Time after which the toast will be closed
    ///   - completion: A completion handler which is invoked after the toast is hidden
    func close(after time: TimeInterval = 0, animated: Bool = true, mode: ToastCloseAnimationType = .transform, completion: (() -> Void)? = nil) {
        if animated {
            UIView.animate(withDuration: config.animationTime, delay: time, options: [.curveEaseIn, .allowUserInteraction], animations: {
                switch mode {
                case .transform:
                    self.view.transform = self.initialTransform
                case .opacity:
                    self.view.alpha = 0
                }
            }, completion: { _ in
                self.view.removeFromSuperview()
                completion?()
            })
        } else {
            view.removeFromSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
