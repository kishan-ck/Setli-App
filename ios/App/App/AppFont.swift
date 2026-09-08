//
//  AppFont.swift
//  App
//
//  Created on 08/09/26.
//

import UIKit
import CoreText

public enum AppFont: String, CaseIterable {
    case regular = "PlusJakartaSans-Regular"
    case medium = "PlusJakartaSans-Medium"
    case semiBold = "PlusJakartaSans-SemiBold"
    case bold = "PlusJakartaSans-Bold"
    case extraBold = "PlusJakartaSans-ExtraBold"

    public var systemWeight: UIFont.Weight {
        switch self {
        case .regular: return .regular
        case .medium: return .medium
        case .semiBold: return .semibold
        case .bold: return .bold
        case .extraBold: return .heavy
        }
    }

    private var alternativeNames: [String] {
        switch self {
        case .regular:
            return ["PlusJakartaSans-Regular", "PlusJakartaSansRoman-Regular", "PlusJakartaSans"]
        case .medium:
            return ["PlusJakartaSans-Medium", "PlusJakartaSansRoman-Medium"]
        case .semiBold:
            return ["PlusJakartaSans-SemiBold", "PlusJakartaSansRoman-SemiBold", "PlusJakartaSans-Semibold"]
        case .bold:
            return ["PlusJakartaSans-Bold", "PlusJakartaSansRoman-Bold"]
        case .extraBold:
            return ["PlusJakartaSans-ExtraBold", "PlusJakartaSansRoman-ExtraBold", "PlusJakartaSans-Extrabold"]
        }
    }

    /// Returns a UIFont with the specified size and weight, falling back gracefully to system font if needed.
    public func size(_ size: CGFloat) -> UIFont {
        // 1. Try primary and alternative PostScript font names
        for name in alternativeNames {
            if let font = UIFont(name: name, size: size) {
                return font
            }
        }

        // 2. Ensure fonts in bundle are registered with CoreText if not yet registered
        AppFont.registerFontsIfNeeded()

        for name in alternativeNames {
            if let font = UIFont(name: name, size: size) {
                return font
            }
        }

        // 3. Fallback to system font with appropriate weight
        return UIFont.systemFont(ofSize: size, weight: systemWeight)
    }

    // Convenience static helpers: AppFont.bold(size: 26)
    public static func regular(size: CGFloat) -> UIFont {
        return AppFont.regular.size(size)
    }

    public static func medium(size: CGFloat) -> UIFont {
        return AppFont.medium.size(size)
    }

    public static func semiBold(size: CGFloat) -> UIFont {
        return AppFont.semiBold.size(size)
    }

    public static func bold(size: CGFloat) -> UIFont {
        return AppFont.bold.size(size)
    }

    public static func extraBold(size: CGFloat) -> UIFont {
        return AppFont.extraBold.size(size)
    }

    // Dynamic runtime registration safeguard
    private static var hasRegistered = false
    private static func registerFontsIfNeeded() {
        guard !hasRegistered else { return }
        hasRegistered = true

        let fontFiles = [
            "PlusJakartaSans-Regular",
            "PlusJakartaSans-Medium",
            "PlusJakartaSans-SemiBold",
            "PlusJakartaSans-Bold",
            "PlusJakartaSans-ExtraBold"
        ]

        for file in fontFiles {
            let urls = [
                Bundle.main.url(forResource: file, withExtension: "ttf"),
                Bundle.main.url(forResource: file, withExtension: "ttf", subdirectory: "fonts")
            ].compactMap { $0 }

            for url in urls {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }
}

// Extension on UIFont for idiomatic syntax: UIFont.appFont(.bold, size: 26)
extension UIFont {
    public static func appFont(_ font: AppFont, size: CGFloat) -> UIFont {
        return font.size(size)
    }
}
