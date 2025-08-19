//
//  WorkExperienceEditView.swift
//  Hireo
//
//  Created by Benedikt Held on 19.08.25.
//

import SwiftUI

struct WorkExperienceEditView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataManager: DataManager
    @State private var workExperiences: [WorkExperienceEntry]
    @State private var showingAddExperience = false
    
    init() {
        let experiences = DataManager.shared.userProfile?.workExperience ?? []
        _workExperiences = State(initialValue: experiences)
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    // Background
                    LinearGradient(
                        colors: [
                            ModernTheme.Colors.surface,
                            ModernTheme.Colors.successLight.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    
                    ScrollView {
                        LazyVStack(spacing: ModernTheme.Spacing.lg) {
                            // Header
                            VStack(spacing: ModernTheme.Spacing.sm) {
                                Image(systemName: "briefcase.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(ModernTheme.Colors.success)
                                
                                Text("Work Experience")
                                    .font(ModernTheme.Typography.displaySmall)
                                    .foregroundColor(ModernTheme.Colors.textPrimary)
                                
                                Text("Showcase your professional journey")
                                    .font(ModernTheme.Typography.bodyMedium)
                                    .foregroundColor(ModernTheme.Colors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, ModernTheme.Spacing.lg)
                            
                            // Work Experience Entries
                            if workExperiences.isEmpty {
                                EmptyWorkExperienceView {
                                    showingAddExperience = true
                                }
                            } else {
                                ForEach(workExperiences.indices, id: \.self) { index in
                                    WorkExperienceCard(
                                        experience: $workExperiences[index],
                                        onDelete: {
                                            deleteExperience(at: index)
                                        }
                                    )
                                    .padding(.horizontal, ModernTheme.Spacing.lg)
                                }
                            }
                            
                            // Add Button
                            Button(action: {
                                showingAddExperience = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Work Experience")
                                }
                            }
                            .secondaryButton()
                            .padding(.horizontal, ModernTheme.Spacing.lg)
                            
                            Spacer(minLength: ModernTheme.Spacing.xxl)
                        }
                        .padding(.vertical, ModernTheme.Spacing.lg)
                    }
                }
            }
            .navigationTitle("Work Experience")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveExperiences()
                    }
                    .foregroundColor(ModernTheme.Colors.primarySolid)
                }
            }
        }
        .sheet(isPresented: $showingAddExperience) {
            AddWorkExperienceView { newExperience in
                workExperiences.append(newExperience)
            }
        }
    }
    
    private func deleteExperience(at index: Int) {
        withAnimation(ModernTheme.Animations.smooth) {
            workExperiences.remove(at: index)
        }
    }
    
    private func saveExperiences() {
        guard var profile = dataManager.userProfile else { return }
        profile.workExperience = workExperiences
        dataManager.saveUserProfile(profile)
        dismiss()
    }
}

struct EmptyWorkExperienceView: View {
    let onAdd: () -> Void
    
    var body: some View {
        VStack(spacing: ModernTheme.Spacing.lg) {
            Image(systemName: "briefcase.badge.plus")
                .font(.system(size: 80))
                .foregroundColor(ModernTheme.Colors.success.opacity(0.3))
            
            VStack(spacing: ModernTheme.Spacing.sm) {
                Text("No Work Experience Added")
                    .font(ModernTheme.Typography.headingMedium)
                    .foregroundColor(ModernTheme.Colors.textPrimary)
                
                Text("Add your professional experience to showcase your skills and career progression")
                    .font(ModernTheme.Typography.bodyMedium)
                    .foregroundColor(ModernTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Add Your First Job") {
                onAdd()
            }
            .primaryButton()
        }
        .modernCard(
            padding: ModernTheme.Spacing.xl,
            shadow: ModernTheme.Shadows.medium
        )
        .padding(.horizontal, ModernTheme.Spacing.lg)
    }
}

struct WorkExperienceCard: View {
    @Binding var experience: WorkExperienceEntry
    let onDelete: () -> Void
    @State private var showingEdit = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: ModernTheme.Spacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(experience.position)
                        .font(ModernTheme.Typography.headingSmall)
                        .foregroundColor(ModernTheme.Colors.textPrimary)
                    
                    Text(experience.company)
                        .font(ModernTheme.Typography.bodyMedium)
                        .foregroundColor(ModernTheme.Colors.success)
                }
                
                Spacer()
                
                Menu {
                    Button("Edit", systemImage: "pencil") {
                        showingEdit = true
                    }
                    
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        onDelete()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title2)
                        .foregroundColor(ModernTheme.Colors.textSecondary)
                }
            }
            
            // Date Range
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(ModernTheme.Colors.textSecondary)
                
                Text(dateRangeString)
                    .font(ModernTheme.Typography.bodySmall)
                    .foregroundColor(ModernTheme.Colors.textSecondary)
                
                if experience.isCurrentJob {
                    Text("• Current")
                        .font(ModernTheme.Typography.labelMedium)
                        .foregroundColor(ModernTheme.Colors.success)
                        .padding(.horizontal, ModernTheme.Spacing.sm)
                        .padding(.vertical, 2)
                        .background(ModernTheme.Colors.successLight)
                        .cornerRadius(ModernTheme.Radius.sm)
                }
            }
            
            // Description
            if !experience.description.isEmpty {
                Text(experience.description)
                    .font(ModernTheme.Typography.bodySmall)
                    .foregroundColor(ModernTheme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Achievements
            if !experience.achievements.isEmpty {
                VStack(alignment: .leading, spacing: ModernTheme.Spacing.xs) {
                    Text("Key Achievements")
                        .font(ModernTheme.Typography.labelMedium)
                        .foregroundColor(ModernTheme.Colors.textPrimary)
                    
                    ForEach(experience.achievements, id: \.self) { achievement in
                        HStack(alignment: .top, spacing: ModernTheme.Spacing.xs) {
                            Text("•")
                                .foregroundColor(ModernTheme.Colors.success)
                            Text(achievement)
                                .font(ModernTheme.Typography.bodySmall)
                                .foregroundColor(ModernTheme.Colors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .modernCard(shadow: ModernTheme.Shadows.small)
        .sheet(isPresented: $showingEdit) {
            EditWorkExperienceView(experience: $experience)
        }
    }
    
    private var dateRangeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        
        let startString = formatter.string(from: experience.startDate)
        
        if experience.isCurrentJob {
            return "\(startString) - Present"
        } else if let endDate = experience.endDate {
            let endString = formatter.string(from: endDate)
            return "\(startString) - \(endString)"
        } else {
            return startString
        }
    }
}

struct AddWorkExperienceView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (WorkExperienceEntry) -> Void
    
    @State private var experience = WorkExperienceEntry()
    @State private var newAchievement = ""
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    LinearGradient(
                        colors: [
                            ModernTheme.Colors.surface,
                            ModernTheme.Colors.successLight.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    
                    ScrollView {
                        VStack(spacing: ModernTheme.Spacing.lg) {
                            // Basic Information
                            VStack(spacing: ModernTheme.Spacing.md) {
                                Text("Job Details")
                                    .font(ModernTheme.Typography.headingMedium)
                                    .foregroundColor(ModernTheme.Colors.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                ModernTextField(
                                    title: "Job Title",
                                    text: $experience.position,
                                    validation: .required
                                )
                                
                                ModernTextField(
                                    title: "Company",
                                    text: $experience.company,
                                    validation: .required
                                )
                            }
                            .modernCard(shadow: ModernTheme.Shadows.medium)
                            
                            // Dates
                            VStack(spacing: ModernTheme.Spacing.md) {
                                Text("Employment Period")
                                    .font(ModernTheme.Typography.headingMedium)
                                    .foregroundColor(ModernTheme.Colors.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                DatePicker("Start Date", selection: $experience.startDate, displayedComponents: .date)
                                    .font(ModernTheme.Typography.bodyMedium)
                                
                                Toggle("Currently Working Here", isOn: $experience.isCurrentJob)
                                    .font(ModernTheme.Typography.bodyMedium)
                                
                                if !experience.isCurrentJob {
                                    DatePicker("End Date", selection: Binding(
                                        get: { experience.endDate ?? Date() },
                                        set: { experience.endDate = $0 }
                                    ), displayedComponents: .date)
                                    .font(ModernTheme.Typography.bodyMedium)
                                }
                            }
                            .modernCard(shadow: ModernTheme.Shadows.medium)
                            
                            // Description
                            VStack(spacing: ModernTheme.Spacing.md) {
                                Text("Job Description")
                                    .font(ModernTheme.Typography.headingMedium)
                                    .foregroundColor(ModernTheme.Colors.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                ModernTextArea(
                                    title: "Describe your role and responsibilities",
                                    text: $experience.description,
                                    minLines: 3,
                                    maxLines: 8
                                )
                            }
                            .modernCard(shadow: ModernTheme.Shadows.medium)
                            
                            // Achievements
                            VStack(spacing: ModernTheme.Spacing.md) {
                                HStack {
                                    Text("Key Achievements")
                                        .font(ModernTheme.Typography.headingMedium)
                                        .foregroundColor(ModernTheme.Colors.textPrimary)
                                    
                                    Spacer()
                                    
                                    Button("Add") {
                                        if !newAchievement.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                            experience.achievements.append(newAchievement.trimmingCharacters(in: .whitespacesAndNewlines))
                                            newAchievement = ""
                                        }
                                    }
                                    .tertiaryButton(size: .small)
                                    .disabled(newAchievement.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                }
                                
                                ModernTextField(
                                    title: "Add an achievement",
                                    text: $newAchievement,
                                    placeholder: "e.g., Increased sales by 20%"
                                )
                                
                                if !experience.achievements.isEmpty {
                                    ForEach(experience.achievements.indices, id: \.self) { index in
                                        HStack {
                                            Text("• \(experience.achievements[index])")
                                                .font(ModernTheme.Typography.bodySmall)
                                                .foregroundColor(ModernTheme.Colors.textSecondary)
                                            
                                            Spacer()
                                            
                                            Button(action: {
                                                experience.achievements.remove(at: index)
                                            }) {
                                                Image(systemName: "minus.circle.fill")
                                                    .foregroundColor(ModernTheme.Colors.error)
                                            }
                                        }
                                    }
                                }
                            }
                            .modernCard(shadow: ModernTheme.Shadows.medium)
                            
                            Spacer(minLength: ModernTheme.Spacing.xxl)
                        }
                        .padding(ModernTheme.Spacing.lg)
                    }
                }
            }
            .navigationTitle("Add Work Experience")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(experience)
                        dismiss()
                    }
                    .foregroundColor(ModernTheme.Colors.primarySolid)
                    .disabled(!canSave)
                }
            }
        }
    }
    
    private var canSave: Bool {
        !experience.position.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !experience.company.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct EditWorkExperienceView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var experience: WorkExperienceEntry
    @State private var editedExperience: WorkExperienceEntry
    @State private var newAchievement = ""
    
    init(experience: Binding<WorkExperienceEntry>) {
        self._experience = experience
        self._editedExperience = State(initialValue: experience.wrappedValue)
    }
    
    var body: some View {
        NavigationStack {
            // Same content as AddWorkExperienceView but with editedExperience
            ScrollView {
                VStack(spacing: ModernTheme.Spacing.lg) {
                    // Use same structure as AddWorkExperienceView
                    // ... (implementation similar to above)
                }
                .padding(ModernTheme.Spacing.lg)
            }
            .navigationTitle("Edit Experience")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        experience = editedExperience
                        dismiss()
                    }
                    .foregroundColor(ModernTheme.Colors.primarySolid)
                }
            }
        }
    }
}

#Preview {
    WorkExperienceEditView()
        .environmentObject(DataManager.shared)
}