//
//  ModernProfileWizardView.swift
//  Hireo
//
//  Created by Benedikt Held on 19.08.25.
//

import SwiftUI

struct ModernProfileWizardView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataManager: DataManager
    @State private var currentStep = 0
    @State private var userProfile = UserProfile()
    @State private var animateContent = false
    
    private let stepTitles = [
        NSLocalizedString("profile.personal_info", comment: ""),
        NSLocalizedString("profile.education", comment: ""),
        NSLocalizedString("profile.work_experience", comment: ""),
        NSLocalizedString("profile.skills", comment: "")
    ]
    
    private let stepIcons = [
        "person.crop.circle.fill",
        "graduationcap.fill",
        "briefcase.fill",
        "star.fill"
    ]
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    // Background
                    LinearGradient(
                        colors: [
                            ModernTheme.Colors.surface,
                            ModernTheme.Colors.primaryLight.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        // Header with Progress
                        VStack(spacing: ModernTheme.Spacing.lg) {
                            // Progress Indicator
                            ModernProgressView(
                                currentStep: currentStep,
                                totalSteps: stepTitles.count,
                                titles: stepTitles,
                                icons: stepIcons
                            )
                            .padding(.horizontal, ModernTheme.Spacing.lg)
                        }
                        .padding(.vertical, ModernTheme.Spacing.lg)
                        .background(ModernTheme.Colors.surface)
                        .shadow(
                            color: ModernTheme.Shadows.small.color,
                            radius: ModernTheme.Shadows.small.radius,
                            y: ModernTheme.Shadows.small.y
                        )
                        
                        // Content Area
                        ScrollView {
                            VStack(spacing: ModernTheme.Spacing.xl) {
                                Spacer(minLength: ModernTheme.Spacing.lg)
                                
                                // Step Content
                                Group {
                                    switch currentStep {
                                    case 0:
                                        ModernPersonalInfoStep(profile: $userProfile)
                                    case 1:
                                        ModernEducationStep(profile: $userProfile)
                                    case 2:
                                        ModernWorkExperienceStep(profile: $userProfile)
                                    case 3:
                                        ModernSkillsStep(profile: $userProfile)
                                    default:
                                        EmptyView()
                                    }
                                }
                                .opacity(animateContent ? 1 : 0)
                                .offset(x: animateContent ? 0 : 30)
                                .animation(ModernTheme.Animations.smooth, value: animateContent)
                                
                                Spacer(minLength: ModernTheme.Spacing.xxxl)
                            }
                            .padding(.horizontal, ModernTheme.Spacing.lg)
                        }
                        
                        // Navigation Buttons
                        VStack(spacing: ModernTheme.Spacing.sm) {
                            HStack(spacing: ModernTheme.Spacing.md) {
                                if currentStep > 0 {
                                    Button(action: previousStep) {
                                        HStack {
                                            Image(systemName: "chevron.left")
                                            Text(NSLocalizedString("previous", comment: ""))
                                        }
                                    }
                                    .secondaryButton()
                                }
                                
                                Button(action: nextStep) {
                                    HStack {
                                        Text(isLastStep ? NSLocalizedString("done", comment: "") : NSLocalizedString("next", comment: ""))
                                        if !isLastStep {
                                            Image(systemName: "chevron.right")
                                        }
                                    }
                                }
                                .primaryButton()
                                .disabled(!canProceed)
                            }
                            
                            if currentStep == 0 {
                                Button(NSLocalizedString("skip", comment: "")) {
                                    dismiss()
                                }
                                .ghostButton(size: .small)
                            }
                        }
                        .padding(ModernTheme.Spacing.lg)
                        .background(ModernTheme.Colors.surface)
                    }
                }
            }
            .navigationBarHidden(true)
            .onChange(of: currentStep) { _, _ in
                animateContent = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    animateContent = true
                }
            }
            .onAppear {
                animateContent = true
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isLastStep: Bool {
        currentStep == stepTitles.count - 1
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 0:
            return !userProfile.personalInfo.firstName.isEmpty &&
                   !userProfile.personalInfo.lastName.isEmpty
        default:
            return true
        }
    }
    
    // MARK: - Actions
    
    private func nextStep() {
        if isLastStep {
            saveProfile()
        } else {
            withAnimation(ModernTheme.Animations.smooth) {
                currentStep += 1
            }
        }
    }
    
    private func previousStep() {
        withAnimation(ModernTheme.Animations.smooth) {
            currentStep -= 1
        }
    }
    
    private func saveProfile() {
        dataManager.saveUserProfile(userProfile)
        dismiss()
    }
}

// MARK: - Modern Progress View

struct ModernProgressView: View {
    let currentStep: Int
    let totalSteps: Int
    let titles: [String]
    let icons: [String]
    
    var body: some View {
        VStack(spacing: ModernTheme.Spacing.md) {
            // Progress Bar
            HStack(spacing: 0) {
                ForEach(0..<totalSteps, id: \.self) { step in
                    Rectangle()
                        .fill(step <= currentStep ? ModernTheme.Colors.primarySolid : ModernTheme.Colors.border)
                        .frame(height: 4)
                        .animation(ModernTheme.Animations.smooth.delay(Double(step) * 0.1), value: currentStep)
                    
                    if step < totalSteps - 1 {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 8, height: 4)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 2))
            
            // Current Step Info
            HStack {
                // Icon
                ZStack {
                    Circle()
                        .fill(ModernTheme.Colors.primary)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icons[currentStep])
                        .font(.title3)
                        .foregroundColor(ModernTheme.Colors.textOnPrimary)
                }
                
                // Title and Progress
                VStack(alignment: .leading, spacing: 2) {
                    Text(titles[currentStep])
                        .font(ModernTheme.Typography.headingMedium)
                        .foregroundColor(ModernTheme.Colors.textPrimary)
                    
                    Text("Step \(currentStep + 1) of \(totalSteps)")
                        .font(ModernTheme.Typography.labelMedium)
                        .foregroundColor(ModernTheme.Colors.textSecondary)
                }
                
                Spacer()
                
                // Progress Percentage
                Text("\(Int((Double(currentStep + 1) / Double(totalSteps)) * 100))%")
                    .font(ModernTheme.Typography.labelLarge)
                    .foregroundColor(ModernTheme.Colors.primarySolid)
            }
        }
    }
}

// MARK: - Step Views

struct ModernPersonalInfoStep: View {
    @Binding var profile: UserProfile
    
    var body: some View {
        VStack(spacing: ModernTheme.Spacing.xl) {
            // Header
            VStack(spacing: ModernTheme.Spacing.sm) {
                Text("Let's start with your basic information")
                    .font(ModernTheme.Typography.headingMedium)
                    .foregroundColor(ModernTheme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("This information will appear on all your documents")
                    .font(ModernTheme.Typography.bodyMedium)
                    .foregroundColor(ModernTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Form Fields
            VStack(spacing: ModernTheme.Spacing.lg) {
                HStack(spacing: ModernTheme.Spacing.md) {
                    ModernTextField(
                        title: NSLocalizedString("profile.first_name", comment: ""),
                        text: $profile.personalInfo.firstName,
                        validation: .required
                    )
                    
                    ModernTextField(
                        title: NSLocalizedString("profile.last_name", comment: ""),
                        text: $profile.personalInfo.lastName,
                        validation: .required
                    )
                }
                
                ModernTextField(
                    title: NSLocalizedString("profile.job_title", comment: ""),
                    text: $profile.personalInfo.title
                )
                
                ModernTextField(
                    title: NSLocalizedString("profile.email", comment: ""),
                    text: $profile.personalInfo.email,
                    keyboardType: .emailAddress,
                    textContentType: .emailAddress,
                    validation: .email
                )
                
                ModernTextField(
                    title: NSLocalizedString("profile.phone", comment: ""),
                    text: $profile.personalInfo.phone,
                    keyboardType: .phonePad,
                    textContentType: .telephoneNumber,
                    validation: .phone
                )
            }
            .modernCard(shadow: ModernTheme.Shadows.medium)
        }
    }
}

struct ModernEducationStep: View {
    @Binding var profile: UserProfile
    
    var body: some View {
        VStack(spacing: ModernTheme.Spacing.xl) {
            VStack(spacing: ModernTheme.Spacing.sm) {
                Text("Your Educational Background")
                    .font(ModernTheme.Typography.headingMedium)
                    .foregroundColor(ModernTheme.Colors.textPrimary)
                
                Text("Add your degrees, certifications, and academic achievements")
                    .font(ModernTheme.Typography.bodyMedium)
                    .foregroundColor(ModernTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: ModernTheme.Spacing.lg) {
                Image(systemName: "graduationcap.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(ModernTheme.Colors.primarySolid)
                
                Text("Education entries will be available in the next update")
                    .font(ModernTheme.Typography.bodyMedium)
                    .foregroundColor(ModernTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                
                Button("Skip for Now") {
                    // Skip to next step
                }
                .tertiaryButton()
            }
            .modernCard(shadow: ModernTheme.Shadows.small)
        }
    }
}

struct ModernWorkExperienceStep: View {
    @Binding var profile: UserProfile
    
    var body: some View {
        VStack(spacing: ModernTheme.Spacing.xl) {
            VStack(spacing: ModernTheme.Spacing.sm) {
                Text("Your Work Experience")
                    .font(ModernTheme.Typography.headingMedium)
                    .foregroundColor(ModernTheme.Colors.textPrimary)
                
                Text("Add your professional experience and achievements")
                    .font(ModernTheme.Typography.bodyMedium)
                    .foregroundColor(ModernTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: ModernTheme.Spacing.lg) {
                Image(systemName: "briefcase.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(ModernTheme.Colors.success)
                
                Text("Work experience entries will be available in the next update")
                    .font(ModernTheme.Typography.bodyMedium)
                    .foregroundColor(ModernTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                
                Button("Skip for Now") {
                    // Skip to next step
                }
                .tertiaryButton()
            }
            .modernCard(shadow: ModernTheme.Shadows.small)
        }
    }
}

struct ModernSkillsStep: View {
    @Binding var profile: UserProfile
    
    var body: some View {
        VStack(spacing: ModernTheme.Spacing.xl) {
            VStack(spacing: ModernTheme.Spacing.sm) {
                Text("Your Skills & Expertise")
                    .font(ModernTheme.Typography.headingMedium)
                    .foregroundColor(ModernTheme.Colors.textPrimary)
                
                Text("Add your technical and soft skills")
                    .font(ModernTheme.Typography.bodyMedium)
                    .foregroundColor(ModernTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: ModernTheme.Spacing.lg) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(ModernTheme.Colors.warning)
                
                Text("Skills management will be available in the next update")
                    .font(ModernTheme.Typography.bodyMedium)
                    .foregroundColor(ModernTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                
                Button("Complete Setup") {
                    // This will be handled by the parent
                }
                .primaryButton()
            }
            .modernCard(shadow: ModernTheme.Shadows.small)
        }
    }
}

#Preview {
    ModernProfileWizardView()
        .environmentObject(DataManager.shared)
}