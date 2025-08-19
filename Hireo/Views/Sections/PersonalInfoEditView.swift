//
//  PersonalInfoEditView.swift
//  Hireo
//
//  Created by Benedikt Held on 19.08.25.
//

import SwiftUI

struct PersonalInfoEditView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataManager: DataManager
    @State private var personalInfo: PersonalInfo
    
    init() {
        let info = DataManager.shared.userProfile?.personalInfo ?? PersonalInfo()
        _personalInfo = State(initialValue: info)
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    // Background
                    LinearGradient(
                        colors: [
                            ModernTheme.Colors.surface,
                            ModernTheme.Colors.primaryLight.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    
                    ScrollView {
                        VStack(spacing: ModernTheme.Spacing.lg) {
                            // Header
                            VStack(spacing: ModernTheme.Spacing.sm) {
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(ModernTheme.Colors.primarySolid)
                                
                                Text("Personal Information")
                                    .font(ModernTheme.Typography.displaySmall)
                                    .foregroundColor(ModernTheme.Colors.textPrimary)
                                
                                Text("Your basic contact information")
                                    .font(ModernTheme.Typography.bodyMedium)
                                    .foregroundColor(ModernTheme.Colors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, ModernTheme.Spacing.lg)
                            
                            // Basic Information
                            VStack(spacing: ModernTheme.Spacing.md) {
                                Text("Basic Details")
                                    .font(ModernTheme.Typography.headingMedium)
                                    .foregroundColor(ModernTheme.Colors.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                HStack(spacing: ModernTheme.Spacing.md) {
                                    ModernTextField(
                                        title: NSLocalizedString("profile.first_name", comment: ""),
                                        text: $personalInfo.firstName,
                                        validation: .required
                                    )
                                    
                                    ModernTextField(
                                        title: NSLocalizedString("profile.last_name", comment: ""),
                                        text: $personalInfo.lastName,
                                        validation: .required
                                    )
                                }
                                
                                ModernTextField(
                                    title: NSLocalizedString("profile.job_title", comment: ""),
                                    text: $personalInfo.title,
                                    placeholder: "e.g., Senior Software Developer"
                                )
                                
                                if personalInfo.dateOfBirth != nil {
                                    DatePicker("Date of Birth", selection: Binding(
                                        get: { personalInfo.dateOfBirth ?? Date() },
                                        set: { personalInfo.dateOfBirth = $0 }
                                    ), displayedComponents: .date)
                                    .font(ModernTheme.Typography.bodyMedium)
                                }
                            }
                            .modernCard(shadow: ModernTheme.Shadows.medium)
                            
                            // Contact Information
                            VStack(spacing: ModernTheme.Spacing.md) {
                                Text("Contact Details")
                                    .font(ModernTheme.Typography.headingMedium)
                                    .foregroundColor(ModernTheme.Colors.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                ModernTextField(
                                    title: NSLocalizedString("profile.email", comment: ""),
                                    text: $personalInfo.email,
                                    keyboardType: .emailAddress,
                                    textContentType: .emailAddress,
                                    validation: .email
                                )
                                
                                ModernTextField(
                                    title: NSLocalizedString("profile.phone", comment: ""),
                                    text: $personalInfo.phone,
                                    keyboardType: .phonePad,
                                    textContentType: .telephoneNumber,
                                    validation: .phone
                                )
                            }
                            .modernCard(shadow: ModernTheme.Shadows.medium)
                            
                            // Address
                            VStack(spacing: ModernTheme.Spacing.md) {
                                Text("Address")
                                    .font(ModernTheme.Typography.headingMedium)
                                    .foregroundColor(ModernTheme.Colors.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                ModernTextField(
                                    title: NSLocalizedString("profile.street", comment: ""),
                                    text: $personalInfo.address.street,
                                    placeholder: "Street address"
                                )
                                
                                HStack(spacing: ModernTheme.Spacing.md) {
                                    ModernTextField(
                                        title: NSLocalizedString("profile.city", comment: ""),
                                        text: $personalInfo.address.city,
                                        placeholder: "City"
                                    )
                                    
                                    ModernTextField(
                                        title: NSLocalizedString("profile.postal_code", comment: ""),
                                        text: $personalInfo.address.postalCode,
                                        placeholder: "ZIP/Postal"
                                    )
                                }
                                
                                ModernTextField(
                                    title: NSLocalizedString("profile.country", comment: ""),
                                    text: $personalInfo.address.country,
                                    placeholder: "Country"
                                )
                            }
                            .modernCard(shadow: ModernTheme.Shadows.medium)
                            
                            Spacer(minLength: ModernTheme.Spacing.xxl)
                        }
                        .padding(ModernTheme.Spacing.lg)
                    }
                }
            }
            .navigationTitle("Personal Information")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        savePersonalInfo()
                    }
                    .foregroundColor(ModernTheme.Colors.primarySolid)
                    .disabled(!canSave)
                }
            }
        }
    }
    
    private var canSave: Bool {
        !personalInfo.firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !personalInfo.lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func savePersonalInfo() {
        guard var profile = dataManager.userProfile else { return }
        profile.personalInfo = personalInfo
        dataManager.saveUserProfile(profile)
        dismiss()
    }
}

#Preview {
    PersonalInfoEditView()
        .environmentObject(DataManager.shared)
}