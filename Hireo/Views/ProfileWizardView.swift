//
//  ProfileWizardView.swift
//  Hireo
//
//  Created by Benedikt Held on 19.08.25.
//

import SwiftUI

struct ProfileWizardView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataManager: DataManager
    @State private var currentStep = 0
    @State private var userProfile = UserProfile()
    
    private let stepTitles = [
        NSLocalizedString("profile.personal_info", comment: ""),
        NSLocalizedString("profile.education", comment: ""),
        NSLocalizedString("profile.work_experience", comment: ""),
        NSLocalizedString("profile.skills", comment: "")
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: ThemeManager.Spacing.lg) {
                StepProgressView(
                    currentStep: currentStep,
                    totalSteps: stepTitles.count,
                    stepTitles: stepTitles
                )
                .padding(.top)
                
                ScrollView {
                    VStack(spacing: ThemeManager.Spacing.lg) {
                        switch currentStep {
                        case 0:
                            PersonalInfoStep(profile: $userProfile)
                        case 1:
                            EducationStep(profile: $userProfile)
                        case 2:
                            WorkExperienceStep(profile: $userProfile)
                        case 3:
                            SkillsStep(profile: $userProfile)
                        default:
                            EmptyView()
                        }
                    }
                    .padding()
                }
                
                Spacer()
                
                HStack(spacing: ThemeManager.Spacing.md) {
                    if currentStep > 0 {
                        Button(NSLocalizedString("previous", comment: "")) {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                        .legacySecondaryButton()
                    }
                    
                    Button(currentStep == stepTitles.count - 1 ? 
                           NSLocalizedString("done", comment: "") :
                           NSLocalizedString("next", comment: "")) {
                        if currentStep == stepTitles.count - 1 {
                            saveProfile()
                        } else {
                            withAnimation {
                                currentStep += 1
                            }
                        }
                    }
                    .legacyPrimaryButton(isEnabled: canProceed)
                }
                .padding()
            }
            .navigationTitle(NSLocalizedString("profile.create_title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("cancel", comment: "")) {
                        dismiss()
                    }
                }
            }
        }
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
    
    private func saveProfile() {
        dataManager.saveUserProfile(userProfile)
        dismiss()
    }
}

struct PersonalInfoStep: View {
    @Binding var profile: UserProfile
    
    var body: some View {
        VStack(spacing: ThemeManager.Spacing.lg) {
            Text(NSLocalizedString("profile.create_subtitle", comment: ""))
                .font(ThemeManager.Fonts.subheadline)
                .foregroundColor(ThemeManager.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: ThemeManager.Spacing.md) {
                VStack(spacing: ThemeManager.Spacing.sm) {
                    TextField(NSLocalizedString("profile.first_name", comment: ""), text: $profile.personalInfo.firstName)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField(NSLocalizedString("profile.last_name", comment: ""), text: $profile.personalInfo.lastName)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField(NSLocalizedString("profile.job_title", comment: ""), text: $profile.personalInfo.title)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField(NSLocalizedString("profile.email", comment: ""), text: $profile.personalInfo.email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField(NSLocalizedString("profile.phone", comment: ""), text: $profile.personalInfo.phone)
                        .keyboardType(.phonePad)
                        .textFieldStyle(.roundedBorder)
                }
            }
            .cardStyle()
            .padding(.horizontal)
        }
    }
}

struct EducationStep: View {
    @Binding var profile: UserProfile
    
    var body: some View {
        VStack(spacing: ThemeManager.Spacing.lg) {
            Text("Add your educational background")
                .font(ThemeManager.Fonts.subheadline)
                .foregroundColor(ThemeManager.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: ThemeManager.Spacing.md) {
                Text("This step will be enhanced in future updates")
                    .font(ThemeManager.Fonts.body)
                    .foregroundColor(ThemeManager.Colors.textSecondary)
                
                Button("Add Education Entry") {
                    // TODO: Implement education entry
                }
                .legacySecondaryButton()
            }
            .cardStyle()
            .padding(.horizontal)
        }
    }
}

struct WorkExperienceStep: View {
    @Binding var profile: UserProfile
    
    var body: some View {
        VStack(spacing: ThemeManager.Spacing.lg) {
            Text("Add your work experience")
                .font(ThemeManager.Fonts.subheadline)
                .foregroundColor(ThemeManager.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: ThemeManager.Spacing.md) {
                Text("This step will be enhanced in future updates")
                    .font(ThemeManager.Fonts.body)
                    .foregroundColor(ThemeManager.Colors.textSecondary)
                
                Button("Add Work Experience") {
                    // TODO: Implement work experience entry
                }
                .legacySecondaryButton()
            }
            .cardStyle()
            .padding(.horizontal)
        }
    }
}

struct SkillsStep: View {
    @Binding var profile: UserProfile
    
    var body: some View {
        VStack(spacing: ThemeManager.Spacing.lg) {
            Text("Add your skills and competencies")
                .font(ThemeManager.Fonts.subheadline)
                .foregroundColor(ThemeManager.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: ThemeManager.Spacing.md) {
                Text("This step will be enhanced in future updates")
                    .font(ThemeManager.Fonts.body)
                    .foregroundColor(ThemeManager.Colors.textSecondary)
                
                Button("Add Skills") {
                    // TODO: Implement skills entry
                }
                .legacySecondaryButton()
            }
            .cardStyle()
            .padding(.horizontal)
        }
    }
}

#Preview {
    ProfileWizardView()
        .environmentObject(DataManager.shared)
}