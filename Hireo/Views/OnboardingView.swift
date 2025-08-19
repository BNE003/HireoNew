//
//  OnboardingView.swift
//  Hireo
//
//  Created by Benedikt Held on 19.08.25.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var dataManager: DataManager
    @State private var showingProfileCreation = false
    @State private var animateElements = false
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    // Background Gradient
                    LinearGradient(
                        colors: [
                            ModernTheme.Colors.surface,
                            ModernTheme.Colors.primaryLight.opacity(0.3),
                            ModernTheme.Colors.surface
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    
                    ScrollView {
                        VStack(spacing: ModernTheme.Spacing.xxxl) {
                            Spacer(minLength: ModernTheme.Spacing.xl)
                            
                            // Hero Section
                            VStack(spacing: ModernTheme.Spacing.lg) {
                                // Logo/Icon with Modern Design
                                ZStack {
                                    RoundedRectangle(cornerRadius: ModernTheme.Radius.xl)
                                        .fill(ModernTheme.Colors.primary)
                                        .frame(width: 120, height: 120)
                                        .shadow(
                                            color: ModernTheme.Colors.primarySolid.opacity(0.3),
                                            radius: 20,
                                            x: 0,
                                            y: 10
                                        )
                                    
                                    Image(systemName: "doc.text.fill")
                                        .font(.system(size: 50, weight: .medium))
                                        .foregroundColor(ModernTheme.Colors.textOnPrimary)
                                }
                                .scaleEffect(animateElements ? 1.0 : 0.8)
                                .animation(ModernTheme.Animations.bouncy.delay(0.1), value: animateElements)
                                
                                // Title and Subtitle
                                VStack(spacing: ModernTheme.Spacing.sm) {
                                    Text(NSLocalizedString("welcome.title", comment: ""))
                                        .font(ModernTheme.Typography.displayMedium)
                                        .foregroundColor(ModernTheme.Colors.textPrimary)
                                        .multilineTextAlignment(.center)
                                        .opacity(animateElements ? 1 : 0)
                                        .offset(y: animateElements ? 0 : 20)
                                        .animation(ModernTheme.Animations.smooth.delay(0.2), value: animateElements)
                                    
                                    Text(NSLocalizedString("welcome.subtitle", comment: ""))
                                        .font(ModernTheme.Typography.bodyLarge)
                                        .foregroundColor(ModernTheme.Colors.textSecondary)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(nil)
                                        .opacity(animateElements ? 1 : 0)
                                        .offset(y: animateElements ? 0 : 20)
                                        .animation(ModernTheme.Animations.smooth.delay(0.3), value: animateElements)
                                }
                                .padding(.horizontal, ModernTheme.Spacing.lg)
                            }
                            
                            // Feature Cards
                            VStack(spacing: ModernTheme.Spacing.md) {
                                FeatureCard(
                                    icon: "person.crop.circle.fill",
                                    title: "Smart Profile",
                                    description: "Step-by-step profile creation",
                                    color: ModernTheme.Colors.success,
                                    delay: 0.4
                                )
                                
                                FeatureCard(
                                    icon: "doc.badge.plus",
                                    title: "Professional Templates",
                                    description: "Modern CV and cover letter designs",
                                    color: ModernTheme.Colors.primarySolid,
                                    delay: 0.5
                                )
                                
                                FeatureCard(
                                    icon: "square.and.arrow.up.fill",
                                    title: "Export & Share",
                                    description: "Generate PDFs instantly",
                                    color: ModernTheme.Colors.warning,
                                    delay: 0.6
                                )
                            }
                            .padding(.horizontal, ModernTheme.Spacing.lg)
                            
                            // Action Section
                            VStack(spacing: ModernTheme.Spacing.md) {
                                Button(action: {
                                    showingProfileCreation = true
                                }) {
                                    HStack {
                                        Text(NSLocalizedString("welcome.get_started", comment: ""))
                                        Image(systemName: "arrow.right")
                                            .font(.headline)
                                    }
                                }
                                .primaryButton(size: .large)
                                .opacity(animateElements ? 1 : 0)
                                .offset(y: animateElements ? 0 : 30)
                                .animation(ModernTheme.Animations.smooth.delay(0.7), value: animateElements)
                                
                                Text(NSLocalizedString("welcome.description", comment: ""))
                                    .font(ModernTheme.Typography.caption)
                                    .foregroundColor(ModernTheme.Colors.textTertiary)
                                    .multilineTextAlignment(.center)
                                    .opacity(animateElements ? 1 : 0)
                                    .animation(ModernTheme.Animations.smooth.delay(0.8), value: animateElements)
                            }
                            .padding(.horizontal, ModernTheme.Spacing.xl)
                            
                            Spacer(minLength: ModernTheme.Spacing.xl)
                        }
                        .frame(minHeight: geometry.size.height)
                    }
                }
            }
        }
        .onAppear {
            animateElements = true
        }
        .sheet(isPresented: $showingProfileCreation) {
            ModernProfileWizardView()
        }
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let delay: Double
    @State private var animate = false
    
    var body: some View {
        HStack(spacing: ModernTheme.Spacing.md) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: ModernTheme.Radius.md)
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(ModernTheme.Typography.headingSmall)
                    .foregroundColor(ModernTheme.Colors.textPrimary)
                
                Text(description)
                    .font(ModernTheme.Typography.bodySmall)
                    .foregroundColor(ModernTheme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .modernCard(shadow: ModernTheme.Shadows.small)
        .opacity(animate ? 1 : 0)
        .offset(x: animate ? 0 : -30)
        .animation(ModernTheme.Animations.smooth.delay(delay), value: animate)
        .onAppear {
            animate = true
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(DataManager.shared)
}