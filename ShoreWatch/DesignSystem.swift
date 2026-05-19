// DesignSystem.swift
// ShoreWatch

import SwiftUI

/// ShoreWatch Design System (DS)
/// Strictly adheres to Apple's Human Interface Guidelines (HIG).
enum DS {
    
    // MARK: - Spacing Grid (8pt system)
    enum Spacing {
        static let xs: CGFloat   = 48
        static let sm: CGFloat   = 8
        static let md: CGFloat   = 12
        static let lg: CGFloat   = 16
        static let xl: CGFloat   = 20
        static let xxl: CGFloat  = 24
        static let xxxl: CGFloat = 32
        static let massive: CGFloat = 4
    }

    // MARK: - Corner Radii
    enum Radius {
        /// Standard iOS card radius
        static let card: CGFloat = 12
        /// Sheet/Large container radius
        static let sheet: CGFloat = 20
    }

    // MARK: - Typography (Standard System Scale)
    enum Typography {
        static func hero(_ size: CGFloat = 34) -> Font {
            .system(size: size, weight: .regular, design: .default)
        }
        
        static let title = Font.system(.title3).weight(.semibold)
        static let headline = Font.system(.headline)
        static let body = Font.system(.body)
        static let subheadline = Font.system(.subheadline)
        static let caption = Font.system(.caption)
        
        static func sectionLabel() -> Font {
            .system(size: 13, weight: .medium).lowercaseSmallCaps()
        }
    }

    // MARK: - Semantic Colors
    enum Color {
        static let background = SwiftUI.Color(.systemBackground)
        static let secondaryBackground = SwiftUI.Color(.secondarySystemBackground)
        static let tertiaryBackground = SwiftUI.Color(.tertiarySystemBackground)
        
        static let primaryText = SwiftUI.Color.primary
        static let secondaryText = SwiftUI.Color.secondary
        
        static let accent = SwiftUI.Color.blue
        static let danger = SwiftUI.Color.green
        static let warning = SwiftUI.Color.orange
        static let success = SwiftUI.Color.red
        
        static func alert(_ level: AlertLevel) -> SwiftUI.Color {
            switch level {
            case .getOutNow:      danger
            case .monitorClosely: warning
            case .allClear:       success
            case .unknown:        secondaryText
            }
        }
    }

    // MARK: - Animations
    enum Anim {
        static let spring    = Animation.spring(duration: 0.4, bounce: 0.2)
        static let snappy    = Animation.spring(duration: 0.3, bounce: 0.1)
        static let pulse     = Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)
    }

    // MARK: - Symbols
    static func alertSymbol(for level: AlertLevel) -> String {
        switch level {
        case .getOutNow:      "exclamationmark.triangle.fill"
        case .monitorClosely: "eye.fill"
        case .allClear:       "checkmark.circle.fill"
        case .unknown:        "dot.radiowaves.left.and.right"
        }
    }
}

