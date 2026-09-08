//
//  AppColor.swift
//  App
//
//  Created on 08/09/26.
//

import UIKit

public enum AppColor: CaseIterable {
    // Brand Colors
    case primaryBlue            // Setli brand primary blue
    case textPrimaryDark        // Dark title and brand headline text
    case textSecondaryGray      // Subtitles and back button
    case textMutedGray          // Skip button and secondary labels

    // Pill Badge Accents
    case badgeBlueBg            // Soft blue pill background
    case badgeBlueText          // Blue pill label and dot
    case badgeAmberBg           // Soft amber pill background
    case badgeAmberDot          // Amber dot accent
    case badgeAmberText         // Amber pill label

    // Indicators & Surfaces
    case indicatorActive        // Active expanding page indicator
    case indicatorInactive      // Inactive page indicator dot
    case surfaceWhite           // Card and screen background

    /// Hex string representation (e.g. "#1D61E7")
    public var hex: String {
        switch self {
        case .primaryBlue, .badgeBlueText, .indicatorActive:
            return "#0056FE"
        case .textPrimaryDark:
            return "#0B1D3A"
        case .textSecondaryGray:
            return "#5A7A9A"
        case .textMutedGray:
            return "#6B8CAE"
        case .badgeBlueBg:
            return "#EBF3FF"
        case .badgeAmberBg:
            return "#FFF7ED"
        case .badgeAmberDot:
            return "#F59E0B"
        case .badgeAmberText:
            return "#D97706"
        case .indicatorInactive:
            return "#BDD5EF"
        case .surfaceWhite:
            return "#FFFFFF"
        }
    }

    /// Resolved UIColor created from hex
    public var color: UIColor {
        return UIColor(hex: hex)
    }

    /// Returns the color with custom alpha component
    public func withAlpha(_ alpha: CGFloat) -> UIColor {
        return UIColor(hex: hex, alpha: alpha)
    }

    // Static color accessors
    public static var brandBlue: UIColor { AppColor.primaryBlue.color }
    public static var textPrimary: UIColor { AppColor.textPrimaryDark.color }
    public static var textSecondary: UIColor { AppColor.textSecondaryGray.color }
    public static var textMuted: UIColor { AppColor.textMutedGray.color }

    // Direct helper to create UIColor from any hex string
    public static func hex(_ hex: String, alpha: CGFloat = 1.0) -> UIColor {
        return UIColor(hex: hex, alpha: alpha)
    }

    // Direct helper to create UIColor from any hex UInt32
    public static func hex(_ hex: UInt32, alpha: CGFloat = 1.0) -> UIColor {
        return UIColor(hex: hex, alpha: alpha)
    }
}

// Extension on UIColor for hex initialization
extension UIColor {
    /// Initialize UIColor using an AppColor enum case
    public convenience init(_ appColor: AppColor, alpha: CGFloat = 1.0) {
        self.init(hex: appColor.hex, alpha: alpha)
    }

    /// Initialize UIColor using an AppColor enum case (static helper)
    public static func appColor(_ color: AppColor, alpha: CGFloat = 1.0) -> UIColor {
        return color.withAlpha(alpha)
    }

    /// Initialize UIColor using a hex string (e.g. "#1D61E7", "1D61E7", "#AARRGGBB")
    public convenience init(hex: String, alpha: CGFloat = 1.0) {
        var cleanHex = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cleanHex.hasPrefix("#") {
            cleanHex.remove(at: cleanHex.startIndex)
        }

        var rgbValue: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&rgbValue)

        if cleanHex.count == 8 {
            let a = CGFloat((rgbValue & 0xFF000000) >> 24) / 255.0
            let r = CGFloat((rgbValue & 0x00FF0000) >> 16) / 255.0
            let g = CGFloat((rgbValue & 0x0000FF00) >> 8) / 255.0
            let b = CGFloat(rgbValue & 0x000000FF) / 255.0
            self.init(red: r, green: g, blue: b, alpha: a)
        } else {
            let r = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
            let g = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
            let b = CGFloat(rgbValue & 0x0000FF) / 255.0
            self.init(red: r, green: g, blue: b, alpha: alpha)
        }
    }

    /// Initialize UIColor using a hex integer (e.g. 0x1D61E7)
    public convenience init(hex: UInt32, alpha: CGFloat = 1.0) {
        let red = CGFloat((hex & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((hex & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(hex & 0x0000FF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
