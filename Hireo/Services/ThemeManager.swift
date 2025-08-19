//
//  ThemeManager.swift
//  Hireo
//
//  Created by Benedikt Held on 19.08.25.
//

import SwiftUI

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    // MARK: - Colors
    struct Colors {
        static let primary = Color.blue
        static let secondary = Color(.systemBlue)
        static let accent = Color(.systemBlue)
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let background = Color(.systemBackground)
        static let secondaryBackground = Color(.secondarySystemBackground)
        static let groupedBackground = Color(.systemGroupedBackground)
        static let cardBackground = Color(.systemBackground)
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
    }
    
    // MARK: - Fonts
    struct Fonts {
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title = Font.title.weight(.semibold)
        static let title2 = Font.title2.weight(.semibold)
        static let headline = Font.headline
        static let body = Font.body
        static let callout = Font.callout
        static let subheadline = Font.subheadline
        static let footnote = Font.footnote
        static let caption = Font.caption
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 6
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 24
    }
    
    // MARK: - Shadows
    struct Shadows {
        static let card = Color.black.opacity(0.1)
        static let cardRadius: CGFloat = 4
        static let cardX: CGFloat = 0
        static let cardY: CGFloat = 2
        
        static let button = Color.black.opacity(0.2)
        static let buttonRadius: CGFloat = 2
        static let buttonX: CGFloat = 0
        static let buttonY: CGFloat = 1
    }
    
    private init() {}
}

// MARK: - View Modifiers
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(ThemeManager.Colors.cardBackground)
            .cornerRadius(ThemeManager.CornerRadius.medium)
            .shadow(
                color: ThemeManager.Shadows.card,
                radius: ThemeManager.Shadows.cardRadius,
                x: ThemeManager.Shadows.cardX,
                y: ThemeManager.Shadows.cardY
            )
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    let isEnabled: Bool
    
    init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ThemeManager.Fonts.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(isEnabled ? ThemeManager.Colors.primary : Color.gray)
            .cornerRadius(ThemeManager.CornerRadius.medium)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .disabled(!isEnabled)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ThemeManager.Fonts.headline)
            .foregroundColor(ThemeManager.Colors.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: ThemeManager.CornerRadius.medium)
                    .stroke(ThemeManager.Colors.primary, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
    }
}

struct SectionHeaderStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(ThemeManager.Fonts.headline)
            .foregroundColor(ThemeManager.Colors.textPrimary)
            .padding(.vertical, ThemeManager.Spacing.sm)
    }
}

struct StatusBadgeStyle: ViewModifier {
    let color: Color
    
    func body(content: Content) -> some View {
        content
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, ThemeManager.Spacing.sm)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(ThemeManager.CornerRadius.small)
    }
}

// MARK: - View Extensions
extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
    
    func sectionHeader() -> some View {
        modifier(SectionHeaderStyle())
    }
    
    func statusBadge(color: Color) -> some View {
        modifier(StatusBadgeStyle(color: color))
    }
}

extension Button {
    func legacyPrimaryButton(isEnabled: Bool = true) -> some View {
        self.buttonStyle(PrimaryButtonStyle(isEnabled: isEnabled))
    }
    
    func legacySecondaryButton() -> some View {
        self.buttonStyle(SecondaryButtonStyle())
    }
}