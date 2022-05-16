//
//  AvatarView.swift
//  AvatarView
//
//  Created by jjaychen on 2021/5/24.
//
import Foundation
import UIKit

public struct Avatar {
    public let image: UIImage?
    public var initials: String = "?"

    public init(image: UIImage? = nil, initials: String = "?") {
        self.image = image
        self.initials = initials
    }
}

/// The implementation detail assumes that the `AvatarView` is
/// absolutely circular.
class AvatarView: UIImageView {
    struct AvatarViewConfiguration {
        var avatar: Avatar

        var placeholderFont: UIFont?
        fileprivate var _defaultPlaceholderFont: UIFont = .preferredFont(forTextStyle: .caption1)
        fileprivate var finalPlaceholderFont: UIFont {
            placeholderFont ?? _defaultPlaceholderFont
        }

        var placeholderTextColor: UIColor = .white
        var fontMinimumScaleFactor: CGFloat = 0.4
        var adjustsFontSizeToFitWidth = true
        var minimumFontSize: CGFloat {
            finalPlaceholderFont.pointSize * fontMinimumScaleFactor
        }

        init(avatar: Avatar) {
            self.avatar = avatar
        }
    }

    // MARK: - Properties

    var configuration: AvatarViewConfiguration = .init(avatar: Avatar(image: nil)) {
        didSet {
            regenerateContent()
        }
    }

    // MARK: - Overridden Properties

    override open var frame: CGRect {
        didSet {
            regenerateContent()
        }
    }

    override open var bounds: CGRect {
        didSet {
            regenerateContent()
        }
    }

    // MARK: - Initializers

    override public init(frame: CGRect) {
        super.init(frame: frame)
        prepareView()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        prepareView()
    }

    public convenience init() {
        self.init(frame: .zero)
        prepareView()
    }

    private func regenerateContent() {
        let recommandFont: UIFont = .systemFont(ofSize: frame.width / 2.5)
        if configuration.placeholderFont == nil, configuration._defaultPlaceholderFont != recommandFont
        {
            configuration._defaultPlaceholderFont = recommandFont
        }

        layer.cornerRadius = frame.width / 2

        if let image = configuration.avatar.image {
            self.image = image
        } else {
            setImageFrom(initials: configuration.avatar.initials)
        }
    }

    private func setImageFrom(initials: String) {
        image = getImageFrom(initials: initials)
    }

    private func getImageFrom(initials: String) -> UIImage {
        let width = frame.width
        let height = frame.height
        if width == 0 || height == 0 { return UIImage() }
        var font = configuration.finalPlaceholderFont

        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }
        let context = UIGraphicsGetCurrentContext()!

        //// Text Drawing
        let textRect = calculateTextRect(outerViewWidth: width, outerViewHeight: height)
        let initialsText = NSAttributedString(string: initials, attributes: [.font: font])
        var text = initials
        if configuration.adjustsFontSizeToFitWidth,
           initialsText.width(considering: textRect.height) > textRect.width {
            let (newFontSize, newText) = calculateFontSize(text: initials, font: font, width: textRect.width, height: textRect.height)
            font = configuration.finalPlaceholderFont.withSize(newFontSize)
            text = newText
        }

        let textStyle = NSMutableParagraphStyle()
        textStyle.alignment = .center
        let textFontAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: configuration.placeholderTextColor, NSAttributedString.Key.paragraphStyle: textStyle]

        let textTextHeight: CGFloat = text.boundingRect(with: CGSize(width: textRect.width, height: CGFloat.infinity), options: .usesLineFragmentOrigin, attributes: textFontAttributes, context: nil).height
        context.saveGState()
        context.clip(to: textRect)
        text.draw(in: CGRect(x: textRect.minX, y: textRect.minY + (textRect.height - textTextHeight) / 2, width: textRect.width, height: textTextHeight), withAttributes: textFontAttributes)
        context.restoreGState()
        guard let renderedImage = UIGraphicsGetImageFromCurrentImageContext() else { assertionFailure("Could not create image from context"); return UIImage() }
        return renderedImage
    }

    /**
     Recursively find the biggest size to fit the text with a given width and height
     */
    private func calculateFontSize(text: String, font: UIFont, width: CGFloat, height: CGFloat) -> (CGFloat, String) {
        let attributedText = NSAttributedString(string: text, attributes: [.font: font])
        if attributedText.height(considering: width) > height {
            let newFont = font.withSize(font.pointSize - 1)
            if newFont.pointSize < configuration.minimumFontSize {
                return (font.pointSize, calculateMaxLengthString(text: text, count: 0, font: font.withSize(configuration.minimumFontSize), width: width, height: height))
            } else {
                return calculateFontSize(text: text, font: newFont, width: width, height: height)
            }
        }
        return (font.pointSize, text)
    }

    private func calculateMaxLengthString(text: String, count: Int, font: UIFont, width: CGFloat, height: CGFloat) -> String {
        let attributedText = NSAttributedString(string: String(text.prefix(count)), attributes: [.font: font])
        if count < text.count, attributedText.height(considering: width) < height {
            return calculateMaxLengthString(text: text, count: count + 1, font: font, width: width, height: height)
        } else {
            return String(text.prefix(max(0, count - 1)))
        }
    }

    /**
     Calculates the inner circle's width.
     Note: Assumes corner radius cannot be more than width/2 (this creates circle).
     */
    private func calculateTextRect(outerViewWidth: CGFloat, outerViewHeight: CGFloat) -> CGRect {
        guard outerViewWidth > 0 else {
            return CGRect.zero
        }
        let shortEdge = min(outerViewHeight, outerViewWidth)

        let w = shortEdge * cos(CGFloat(30).degreesToRadians)
        let h = shortEdge * sin(CGFloat(30).degreesToRadians)
        let startX = (outerViewWidth - w) / 2
        let startY = (outerViewHeight - h) / 2
        // In case the font exactly fits to the region, put 2 pixel both left and right
        return CGRect(x: startX + 2, y: startY, width: w - 4, height: h)
    }

    // MARK: - Internal methods

    private func prepareView() {
        backgroundColor = .systemGray
        contentMode = .scaleAspectFill
        layer.masksToBounds = true
        clipsToBounds = true
        layer.cornerRadius = 0
    }
}

private extension FloatingPoint {
    var degreesToRadians: Self { return self * .pi / 180 }
    var radiansToDegrees: Self { return self * 180 / .pi }
}

private extension NSAttributedString {
    func width(considering height: CGFloat) -> CGFloat {
        let size = self.size(consideringHeight: height)
        return size.width
    }

    func height(considering width: CGFloat) -> CGFloat {
        let size = self.size(consideringWidth: width)
        return size.height
    }

    func size(consideringHeight height: CGFloat) -> CGSize {
        let constraintBox = CGSize(width: .greatestFiniteMagnitude, height: height)
        return size(considering: constraintBox)
    }

    func size(consideringWidth width: CGFloat) -> CGSize {
        let constraintBox = CGSize(width: width, height: .greatestFiniteMagnitude)
        return size(considering: constraintBox)
    }

    func size(considering size: CGSize) -> CGSize {
        let rect = boundingRect(with: size, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        return rect.size
    }
}
