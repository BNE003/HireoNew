//
//  ModernTheme.swift
//  Hireo
//
//  Created by Benedikt Held on 19.08.25.
//

import SwiftUI

struct ModernTheme {
    
    // MARK: - Color System
    struct Colors {
        // Primary Brand Colors
        static let primary = LinearGradient(
            colors: [Color(#colorLiteral(red: 0.4, green: 0.6, blue: 1, alpha: 1)), Color(#colorLiteral(red: 0.2, green: 0.4, blue: 0.9, alpha: 1))],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let primarySolid = Color(#colorLiteral(red: 0.3, green: 0.5, blue: 0.95, alpha: 1))
        static let primaryLight = Color(#colorLiteral(red: 0.4, green: 0.6, blue: 1, alpha: 0.1))
        
        // Semantic Colors
        static let success = Color(#colorLiteral(red: 0.2, green: 0.8, blue: 0.4, alpha: 1))
        static let successLight = Color(#colorLiteral(red: 0.2, green: 0.8, blue: 0.4, alpha: 0.1))
        
        static let warning = Color(#colorLiteral(red: 1, green: 0.6, blue: 0.2, alpha: 1))
        static let warningLight = Color(#colorLiteral(red: 1, green: 0.6, blue: 0.2, alpha: 0.1))
        
        static let error = Color(#colorLiteral(red: 1, green: 0.3, blue: 0.3, alpha: 1))
        static let errorLight = Color(#colorLiteral(red: 1, green: 0.3, blue: 0.3, alpha: 0.1))
        
        // Neutral Colors
        static let surface = Color(.systemBackground)
        static let surfaceSecondary = Color(.secondarySystemBackground)
        static let surfaceTertiary = Color(.tertiarySystemBackground)
        
        // Text Colors
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
        static let textTertiary = Color(.tertiaryLabel)
        static let textOnPrimary = Color.white
        
        // Border Colors
        static let border = Color(.separator)
        static let borderLight = Color(.separator).opacity(0.3)
    }
    
    // MARK: - Typography System
    struct Typography {
        // Display Fonts (Large Headers)
        static let displayLarge = Font.system(size: 34, weight: .bold, design: .rounded)
        static let displayMedium = Font.system(size: 28, weight: .bold, design: .rounded)
        static let displaySmall = Font.system(size: 24, weight: .semibold, design: .rounded)
        
        // Heading Fonts
        static let headingLarge = Font.system(size: 22, weight: .semibold, design: .default)
        static let headingMedium = Font.system(size: 20, weight: .semibold, design: .default)
        static let headingSmall = Font.system(size: 18, weight: .medium, design: .default)
        
        // Body Fonts
        static let bodyLarge = Font.system(size: 17, weight: .regular, design: .default)
        static let bodyMedium = Font.system(size: 16, weight: .regular, design: .default)
        static let bodySmall = Font.system(size: 14, weight: .regular, design: .default)
        
        // Label Fonts
        static let labelLarge = Font.system(size: 14, weight: .medium, design: .default)
        static let labelMedium = Font.system(size: 12, weight: .medium, design: .default)
        static let labelSmall = Font.system(size: 11, weight: .medium, design: .default)
        
        // Caption
        static let caption = Font.system(size: 12, weight: .regular, design: .default)
    }
    
    // MARK: - Spacing System
    struct Spacing {
        static let xs: CGFloat = 4      // 4pt
        static let sm: CGFloat = 8      // 8pt
        static let md: CGFloat = 16     // 16pt
        static let lg: CGFloat = 24     // 24pt
        static let xl: CGFloat = 32     // 32pt
        static let xxl: CGFloat = 48    // 48pt
        static let xxxl: CGFloat = 64   // 64pt
    }
    
    // MARK: - Radius System
    struct Radius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let full: CGFloat = 999
    }
    
    // MARK: - Shadow System
    struct Shadows {
        static let small = Shadow(
            color: Color.black.opacity(0.08),
            radius: 4,
            x: 0,
            y: 2
        )
        
        static let medium = Shadow(
            color: Color.black.opacity(0.12),
            radius: 8,
            x: 0,
            y: 4
        )
        
        static let large = Shadow(
            color: Color.black.opacity(0.16),
            radius: 16,
            x: 0,
            y: 8
        )
        
        static let extraLarge = Shadow(
            color: Color.black.opacity(0.20),
            radius: 24,
            x: 0,
            y: 12
        )
    }
    
    // MARK: - Animation System
    struct Animations {
        static let quick = Animation.easeInOut(duration: 0.2)
        static let smooth = Animation.easeInOut(duration: 0.3)
        static let gentle = Animation.easeInOut(duration: 0.5)
        static let spring = Animation.spring(response: 0.5, dampingFraction: 0.8)
        static let bouncy = Animation.spring(response: 0.3, dampingFraction: 0.6)
    }
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Modern View Modifiers

struct ModernCardStyle: ViewModifier {
    let padding: CGFloat
    let shadow: Shadow
    
    init(padding: CGFloat = ModernTheme.Spacing.md, shadow: Shadow = ModernTheme.Shadows.small) {
        self.padding = padding
        self.shadow = shadow
    }
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: ModernTheme.Radius.md)
                    .fill(ModernTheme.Colors.surface)
                    .shadow(
                        color: shadow.color,
                        radius: shadow.radius,
                        x: shadow.x,
                        y: shadow.y
                    )
            )
    }
}

struct PremiumButtonStyle: ButtonStyle {
    let style: ButtonStyleType
    let size: ButtonSize
    
    enum ButtonStyleType {
        case primary, secondary, tertiary, ghost
    }
    
    enum ButtonSize {
        case small, medium, large
        
        var height: CGFloat {
            switch self {
            case .small: return 36
            case .medium: return 44
            case .large: return 52
            }
        }
        
        var font: Font {
            switch self {
            case .small: return ModernTheme.Typography.labelMedium
            case .medium: return ModernTheme.Typography.labelLarge
            case .large: return ModernTheme.Typography.headingSmall
            }
        }
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size.font)
            .foregroundColor(foregroundColor(for: style, isPressed: configuration.isPressed))
            .frame(maxWidth: .infinity)
            .frame(height: size.height)
            .background(background(for: style, isPressed: configuration.isPressed))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(ModernTheme.Animations.quick, value: configuration.isPressed)
    }
    
    private func foregroundColor(for style: ButtonStyleType, isPressed: Bool) -> Color {
        switch style {
        case .primary:
            return ModernTheme.Colors.textOnPrimary
        case .secondary:
            return ModernTheme.Colors.primarySolid
        case .tertiary:
            return ModernTheme.Colors.textPrimary
        case .ghost:
            return ModernTheme.Colors.primarySolid
        }
    }
    
    private func background(for style: ButtonStyleType, isPressed: Bool) -> AnyView {
        let opacity = isPressed ? 0.8 : 1.0
        
        switch style {
        case .primary:
            return AnyView(
                RoundedRectangle(cornerRadius: ModernTheme.Radius.md)
                    .fill(ModernTheme.Colors.primary)
                    .opacity(opacity)
                    .shadow(
                        color: ModernTheme.Colors.primarySolid.opacity(0.3),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
        case .secondary:
            return AnyView(
                RoundedRectangle(cornerRadius: ModernTheme.Radius.md)
                    .fill(ModernTheme.Colors.primaryLight)
                    .opacity(opacity)
                    .overlay(
                        RoundedRectangle(cornerRadius: ModernTheme.Radius.md)
                            .stroke(ModernTheme.Colors.primarySolid.opacity(0.2), lineWidth: 1)
                    )
            )
        case .tertiary:
            return AnyView(
                RoundedRectangle(cornerRadius: ModernTheme.Radius.md)
                    .fill(ModernTheme.Colors.surfaceSecondary)
                    .opacity(opacity)
            )
        case .ghost:
            return AnyView(
                RoundedRectangle(cornerRadius: ModernTheme.Radius.md)
                    .fill(Color.clear)
                    .opacity(opacity)
            )
        }
    }
}

// MARK: - View Extensions
extension View {
    func modernCard(padding: CGFloat = ModernTheme.Spacing.md, shadow: Shadow = ModernTheme.Shadows.small) -> some View {
        modifier(ModernCardStyle(padding: padding, shadow: shadow))
    }
}

extension Button {
    func primaryButton(size: PremiumButtonStyle.ButtonSize = .medium) -> some View {
        buttonStyle(PremiumButtonStyle(style: .primary, size: size))
    }
    
    func secondaryButton(size: PremiumButtonStyle.ButtonSize = .medium) -> some View {
        buttonStyle(PremiumButtonStyle(style: .secondary, size: size))
    }
    
    func tertiaryButton(size: PremiumButtonStyle.ButtonSize = .medium) -> some View {
        buttonStyle(PremiumButtonStyle(style: .tertiary, size: size))
    }
    
    func ghostButton(size: PremiumButtonStyle.ButtonSize = .medium) -> some View {
        buttonStyle(PremiumButtonStyle(style: .ghost, size: size))
    }
}