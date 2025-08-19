//
//  ModernProfileView.swift
//  Hireo
//
//  Created by Benedikt Held on 19.08.25.
//

import SwiftUI

struct ModernProfileView: View {
    @EnvironmentObject private var dataManager: DataManager
    @State private var showingProfileEdit = false
    @State private var animateCards = false
    
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
                    
                    ScrollView {
                        LazyVStack(spacing: ModernTheme.Spacing.lg) {
                            // Profile Header
                            if let profile = dataManager.userProfile {
                                ModernProfileHeader(profile: profile)
                                    .padding(.horizontal, ModernTheme.Spacing.lg)
                                    .opacity(animateCards ? 1 : 0)
                                    .offset(y: animateCards ? 0 : -20)
                                    .animation(ModernTheme.Animations.smooth.delay(0.1), value: animateCards)
                                
                                // Profile Sections
                                LazyVStack(spacing: ModernTheme.Spacing.md) {
                                    ModernProfileSection(
                                        title: "Personal Information",
                                        icon: "person.crop.circle.fill",
                                        count: 1,
                                        color: ModernTheme.Colors.primarySolid,
                                        delay: 0.2,
                                        sectionType: .personalInfo
                                    )
                                    
                                    ModernProfileSection(
                                        title: "Education",
                                        icon: "graduationcap.fill",
                                        count: profile.education.count,
                                        color: ModernTheme.Colors.success,
                                        delay: 0.3,
                                        sectionType: .education
                                    )
                                    
                                    ModernProfileSection(
                                        title: "Work Experience",
                                        icon: "briefcase.fill",
                                        count: profile.workExperience.count,
                                        color: ModernTheme.Colors.warning,
                                        delay: 0.4,
                                        sectionType: .workExperience
                                    )
                                    
                                    ModernProfileSection(
                                        title: "Skills",
                                        icon: "star.fill",
                                        count: profile.skills.reduce(0) { $0 + $1.skills.count },
                                        color: Color.purple,
                                        delay: 0.5,
                                        sectionType: .skills
                                    )
                                    
                                    ModernProfileSection(
                                        title: "Projects",
                                        icon: "folder.badge.plus",
                                        count: profile.projects.count,
                                        color: Color.indigo,
                                        delay: 0.6,
                                        sectionType: .projects
                                    )
                                    
                                    ModernProfileSection(
                                        title: "Languages",
                                        icon: "globe",
                                        count: profile.languages.count,
                                        color: Color.cyan,
                                        delay: 0.7,
                                        sectionType: .languages
                                    )
                                }
                                .padding(.horizontal, ModernTheme.Spacing.lg)
                            }
                            
                            Spacer(minLength: ModernTheme.Spacing.xl)
                        }
                        .padding(.vertical, ModernTheme.Spacing.lg)
                    }
                }
            }
            .navigationTitle(NSLocalizedString("profile", comment: ""))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingProfileEdit = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(ModernTheme.Colors.primaryLight)
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "pencil")
                                .font(.title3)
                                .foregroundColor(ModernTheme.Colors.primarySolid)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .onAppear {
            animateCards = true
        }
        .sheet(isPresented: $showingProfileEdit) {
            ModernProfileEditView()
        }
    }
}

struct ModernProfileHeader: View {
    let profile: UserProfile
    
    var body: some View {
        VStack(spacing: ModernTheme.Spacing.lg) {
            // Profile Image and Info
            HStack(spacing: ModernTheme.Spacing.md) {
                // Profile Image
                ZStack {
                    Circle()
                        .fill(ModernTheme.Colors.primary)
                        .frame(width: 80, height: 80)
                        .shadow(
                            color: ModernTheme.Colors.primarySolid.opacity(0.3),
                            radius: 10,
                            y: 5
                        )
                    
                    if let imageData = profile.personalInfo.profileImageData,
                       let image = UIImage(data: imageData) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    } else {
                        Text("\(profile.personalInfo.firstName.prefix(1))\(profile.personalInfo.lastName.prefix(1))")
                            .font(ModernTheme.Typography.headingLarge)
                            .foregroundColor(ModernTheme.Colors.textOnPrimary)
                    }
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(profile.personalInfo.firstName) \(profile.personalInfo.lastName)")
                        .font(ModernTheme.Typography.headingLarge)
                        .foregroundColor(ModernTheme.Colors.textPrimary)
                    
                    if !profile.personalInfo.title.isEmpty {
                        Text(profile.personalInfo.title)
                            .font(ModernTheme.Typography.bodyMedium)
                            .foregroundColor(ModernTheme.Colors.textSecondary)
                    }
                    
                    if !profile.personalInfo.email.isEmpty {
                        Text(profile.personalInfo.email)
                            .font(ModernTheme.Typography.bodySmall)
                            .foregroundColor(ModernTheme.Colors.textSecondary)
                    }
                }
                
                Spacer()
            }
        }
        .modernCard(padding: ModernTheme.Spacing.lg, shadow: ModernTheme.Shadows.medium)
    }
}

enum ProfileSectionType {
    case personalInfo, education, workExperience, skills, projects, languages
}

struct ModernProfileSection: View {
    let title: String
    let icon: String
    let count: Int
    let color: Color
    let delay: Double
    let sectionType: ProfileSectionType
    @State private var animate = false
    @State private var showingEdit = false
    
    var body: some View {
        Button(action: {
            showingEdit = true
        }) {
            HStack(spacing: ModernTheme.Spacing.md) {
                // Icon Background
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
                    
                    Text("\(count) item\(count != 1 ? "s" : "")")
                        .font(ModernTheme.Typography.bodySmall)
                        .foregroundColor(ModernTheme.Colors.textSecondary)
                }
                
                Spacer()
                
                // Count Badge
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 32, height: 32)
                    
                    Text("\(count)")
                        .font(ModernTheme.Typography.labelMedium)
                        .foregroundColor(color)
                }
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(ModernTheme.Colors.textTertiary)
            }
            .modernCard(shadow: ModernTheme.Shadows.small)
            .opacity(animate ? 1 : 0)
            .offset(x: animate ? 0 : -30)
            .animation(ModernTheme.Animations.smooth.delay(delay), value: animate)
        }
        .buttonStyle(.plain)
        .onAppear {
            animate = true
        }
        .sheet(isPresented: $showingEdit) {
            sectionEditView
        }
    }
    
    @ViewBuilder
    private var sectionEditView: some View {
        switch sectionType {
        case .personalInfo:
            PersonalInfoEditView()
        case .education:
            EducationEditView()
        case .workExperience:
            WorkExperienceEditView()
        case .skills:
            SkillsEditView()
        case .projects:
            Text("Projects editing coming soon")
        case .languages:
            LanguagesEditView()
        }
    }
}

#Preview {
    NavigationStack {
        ModernProfileView()
            .environmentObject(DataManager.shared)
    }
}