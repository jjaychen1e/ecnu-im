//
//  DatePickerToast.swift
//  ecnu-im
//
//  Created by Junjie Chen on 2022/8/30.
//

import SwiftUI

struct DatePickerToast: View {
    @Binding var date: Date
    @State var onDismiss: () -> Void
    @State var onConfirm: (Date) -> Void
    
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            Text("请选择目标学期第一周的周一")
                .font(.headline)
            Rectangle()
                .frame(height: 1)
                .padding(.top, 6)
            DatePicker(
                "请选择目标学期第一周的周一",
                selection: $date,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .background(.background)
            HStack {
                Button {
                    onDismiss()
                } label: {
                    Text("取消")
                }
                Spacer(minLength: 0)
                Button {
                    if case .monday = date.getWeekDay() {
                        onConfirm(date)
                    } else {
                        Toast.default(icon: .emoji("⚠️"), title: "选择的日期不是周一").show()
                    }
                } label: {
                    Text("确定")
                        .bold()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.background)
                .border(.background)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .primary.opacity(colorScheme == .light ? 0.1 : 0), radius: 10)
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .background {
            Color.clear
                .onTapGesture {
                    onDismiss()
                }
        }
        .ignoresSafeArea()
    }
}

struct DatePickerToast_Previews: PreviewProvider {
    static var previews: some View {
        DatePickerToast(date: .constant(Date()), onDismiss: {}, onConfirm: { _ in })
    }
}

class DatePickerToastViewController: UIViewController {
    private var date = Date()
    private let completion: (Date?) -> Void

    init(completion: @escaping (Date?) -> Void) {
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear

        let datePickerView = DatePickerToast(date: .init(get: { [weak self] in
            self?.date ?? Date()
        }, set: { [weak self] newDate in
            self?.date = newDate
        }),
        onDismiss: { [weak self] in
            self?.dismiss(animated: true) {
                self?.completion(nil)
            }
        },
        onConfirm: { [weak self] date in
            self?.dismiss(animated: true) {
                self?.completion(date)
            }
        })
        let hostingVC = UIHostingController(rootView: datePickerView)
        hostingVC.view.backgroundColor = .clear
        addChildViewController(hostingVC, addConstrains: true)
    }

    static func show(completion: @escaping (Date?) -> Void) {
        let vc = DatePickerToastViewController(completion: completion)
        vc.modalPresentationStyle = .overCurrentContext
        vc.modalTransitionStyle = .crossDissolve
        UIApplication.shared.presentOnTop(vc, animated: true)
    }
}
