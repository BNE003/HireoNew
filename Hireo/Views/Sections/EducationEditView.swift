//
//  EducationEditView.swift
//  Hireo
//
//  Created by Benedikt Held on 19.08.25.
//

import SwiftUI

struct EducationEditView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataManager: DataManager
    @State private var educationEntries: [EducationEntry]
    @State private var showingAddEducation = false
    
    init() {
        let education = DataManager.shared.userProfile?.education ?? []
        _educationEntries = State(initialValue: education)
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    // Background
                    LinearGradient(
                        colors: [
                            ModernTheme.Colors.surface,
                            ModernTheme.Colors.successLight.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    
                    ScrollView {
                        LazyVStack(spacing: ModernTheme.Spacing.lg) {
                            // Header
                            VStack(spacing: ModernTheme.Spacing.sm) {
                                Image(systemName: "graduationcap.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(ModernTheme.Colors.success)
                                
                                Text("Education")
                                    .font(ModernTheme.Typography.displaySmall)
                                    .foregroundColor(ModernTheme.Colors.textPrimary)
                                
                                Text("Your academic achievements and qualifications")
                                    .font(ModernTheme.Typography.bodyMedium)
                                    .foregroundColor(ModernTheme.Colors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, ModernTheme.Spacing.lg)
                            
                            // Education Entries
                            if educationEntries.isEmpty {
                                EmptyEducationView {
                                    showingAddEducation = true
                                }
                            } else {
                                ForEach(educationEntries.indices, id: \.self) { index in
                                    EducationCard(
                                        education: $educationEntries[index],
                                        onDelete: {
                                            deleteEducation(at: index)
                                        }
                                    )
                                    .padding(.horizontal, ModernTheme.Spacing.lg)
                                }
                            }
                            
                            // Add Button
                            Button(action: {
                                showingAddEducation = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Education")
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
            .navigationTitle("Education")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveEducation()
                    }
                    .foregroundColor(ModernTheme.Colors.primarySolid)
                }
            }
        }
        .sheet(isPresented: $showingAddEducation) {
            AddEducationView { newEducation in
                educationEntries.append(newEducation)
            }
        }
    }
    
    private func deleteEducation(at index: Int) {
        withAnimation(ModernTheme.Animations.smooth) {
            educationEntries.remove(at: index)
        }
    }
    
    private func saveEducation() {
        guard var profile = dataManager.userProfile else { return }
        profile.education = educationEntries
        dataManager.saveUserProfile(profile)
        dismiss()
    }
}

struct EmptyEducationView: View {
    let onAdd: () -> Void
    
    var body: some View {
        VStack(spacing: ModernTheme.Spacing.lg) {
            Image(systemName: "graduationcap.badge.plus")
                .font(.system(size: 80))
                .foregroundColor(ModernTheme.Colors.success.opacity(0.3))
            
            VStack(spacing: ModernTheme.Spacing.sm) {
                Text("No Education Added")
                    .font(ModernTheme.Typography.headingMedium)
                    .foregroundColor(ModernTheme.Colors.textPrimary)
                
                Text("Add your educational background including degrees, certifications, and courses")
                    .font(ModernTheme.Typography.bodyMedium)
                    .foregroundColor(ModernTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Add Your First Education") {
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

struct EducationCard: View {
    @Binding var education: EducationEntry
    let onDelete: () -> Void
    @State private var showingEdit = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: ModernTheme.Spacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(education.degree)
                        .font(ModernTheme.Typography.headingSmall)
                        .foregroundColor(ModernTheme.Colors.textPrimary)
                    
                    if !education.fieldOfStudy.isEmpty {
                        Text(education.fieldOfStudy)
                            .font(ModernTheme.Typography.bodyMedium)
                            .foregroundColor(ModernTheme.Colors.success)
                    }
                    
                    Text(education.institution)
                        .font(ModernTheme.Typography.bodyMedium)
                        .foregroundColor(ModernTheme.Colors.textSecondary)
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
            
            // Date Range and Status
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(ModernTheme.Colors.textSecondary)
                
                Text(dateRangeString)
                    .font(ModernTheme.Typography.bodySmall)
                    .foregroundColor(ModernTheme.Colors.textSecondary)
                
                if education.isCurrentlyStudying {
                    Text("• Current")
                        .font(ModernTheme.Typography.labelMedium)
                        .foregroundColor(ModernTheme.Colors.success)
                        .padding(.horizontal, ModernTheme.Spacing.sm)
                        .padding(.vertical, 2)
                        .background(ModernTheme.Colors.successLight)
                        .cornerRadius(ModernTheme.Radius.sm)
                }
                
                Spacer()
                
                if !education.grade.isEmpty {
                    Text("Grade: \(education.grade)")
                        .font(ModernTheme.Typography.bodySmall)
                        .foregroundColor(ModernTheme.Colors.success)
                        .padding(.horizontal, ModernTheme.Spacing.sm)
                        .padding(.vertical, 2)
                        .background(ModernTheme.Colors.successLight)
                        .cornerRadius(ModernTheme.Radius.sm)
                }
            }
            
            // Description
            if !education.description.isEmpty {
                Text(education.description)
                    .font(ModernTheme.Typography.bodySmall)
                    .foregroundColor(ModernTheme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .modernCard(shadow: ModernTheme.Shadows.small)
        .sheet(isPresented: $showingEdit) {
            EditEducationView(education: $education)
        }
    }
    
    private var dateRangeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        
        let startString = formatter.string(from: education.startDate)
        
        if education.isCurrentlyStudying {
            return "\(startString) - Present"
        } else if let endDate = education.endDate {
            let endString = formatter.string(from: endDate)
            return "\(startString) - \(endString)"
        } else {
            return startString
        }
    }
}

struct AddEducationView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (EducationEntry) -> Void
    
    @State private var education = EducationEntry()
    
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
                                Text("Education Details")
                                    .font(ModernTheme.Typography.headingMedium)
                                    .foregroundColor(ModernTheme.Colors.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                ModernTextField(
                                    title: "Institution",
                                    text: $education.institution,
                                    placeholder: "University of Example",
                                    validation: .required
                                )
                                
                                ModernTextField(
                                    title: "Degree",
                                    text: $education.degree,
                                    placeholder: "Bachelor of Science",
                                    validation: .required
                                )
                                
                                ModernTextField(
                                    title: "Field of Study",
                                    text: $education.fieldOfStudy,
                                    placeholder: "Computer Science"
                                )
                                
                                ModernTextField(
                                    title: "Grade/GPA",
                                    text: $education.grade,
                                    placeholder: "3.8/4.0 or First Class"
                                )
                            }
                            .modernCard(shadow: ModernTheme.Shadows.medium)
                            
                            // Dates
                            VStack(spacing: ModernTheme.Spacing.md) {
                                Text("Study Period")
                                    .font(ModernTheme.Typography.headingMedium)
                                    .foregroundColor(ModernTheme.Colors.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                DatePicker("Start Date", selection: $education.startDate, displayedComponents: .date)
                                    .font(ModernTheme.Typography.bodyMedium)
                                
                                Toggle("Currently Studying", isOn: $education.isCurrentlyStudying)
                                    .font(ModernTheme.Typography.bodyMedium)
                                
                                if !education.isCurrentlyStudying {
                                    DatePicker("End Date", selection: Binding(
                                        get: { education.endDate ?? Date() },
                                        set: { education.endDate = $0 }
                                    ), displayedComponents: .date)
                                    .font(ModernTheme.Typography.bodyMedium)
                                }
                            }
                            .modernCard(shadow: ModernTheme.Shadows.medium)
                            
                            // Description
                            VStack(spacing: ModernTheme.Spacing.md) {
                                Text("Additional Information")
                                    .font(ModernTheme.Typography.headingMedium)
                                    .foregroundColor(ModernTheme.Colors.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                ModernTextArea(
                                    title: "Relevant coursework, achievements, or activities",
                                    text: $education.description,
                                    placeholder: "Relevant coursework, thesis topic, awards, activities...",
                                    minLines: 3,
                                    maxLines: 6
                                )
                            }
                            .modernCard(shadow: ModernTheme.Shadows.medium)
                            
                            Spacer(minLength: ModernTheme.Spacing.xxl)
                        }
                        .padding(ModernTheme.Spacing.lg)
                    }
                }
            }
            .navigationTitle("Add Education")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(education)
                        dismiss()
                    }
                    .foregroundColor(ModernTheme.Colors.primarySolid)
                    .disabled(!canSave)
                }
            }
        }
    }
    
    private var canSave: Bool {
        !education.institution.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !education.degree.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct EditEducationView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var education: EducationEntry
    @State private var editedEducation: EducationEntry
    
    init(education: Binding<EducationEntry>) {
        self._education = education
        self._editedEducation = State(initialValue: education.wrappedValue)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: ModernTheme.Spacing.lg) {
                    // Basic Information
                    VStack(spacing: ModernTheme.Spacing.md) {
                        Text("Education Details")
                            .font(ModernTheme.Typography.headingMedium)
                            .foregroundColor(ModernTheme.Colors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        ModernTextField(
                            title: "Institution",
                            text: $editedEducation.institution,
                            validation: .required
                        )
                        
                        ModernTextField(
                            title: "Degree",
                            text: $editedEducation.degree,
                            validation: .required
                        )
                        
                        ModernTextField(
                            title: "Field of Study",
                            text: $editedEducation.fieldOfStudy
                        )
                        
                        ModernTextField(
                            title: "Grade/GPA",
                            text: $editedEducation.grade
                        )
                    }
                    .modernCard(shadow: ModernTheme.Shadows.medium)
                    
                    // Dates
                    VStack(spacing: ModernTheme.Spacing.md) {
                        Text("Study Period")
                            .font(ModernTheme.Typography.headingMedium)
                            .foregroundColor(ModernTheme.Colors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        DatePicker("Start Date", selection: $editedEducation.startDate, displayedComponents: .date)
                        
                        Toggle("Currently Studying", isOn: $editedEducation.isCurrentlyStudying)
                        
                        if !editedEducation.isCurrentlyStudying {
                            DatePicker("End Date", selection: Binding(
                                get: { editedEducation.endDate ?? Date() },
                                set: { editedEducation.endDate = $0 }
                            ), displayedComponents: .date)
                        }
                    }
                    .modernCard(shadow: ModernTheme.Shadows.medium)
                    
                    // Description
                    VStack(spacing: ModernTheme.Spacing.md) {
                        Text("Additional Information")
                            .font(ModernTheme.Typography.headingMedium)
                            .foregroundColor(ModernTheme.Colors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        ModernTextArea(
                            title: "Relevant coursework, achievements, or activities",
                            text: $editedEducation.description,
                            minLines: 3,
                            maxLines: 6
                        )
                    }
                    .modernCard(shadow: ModernTheme.Shadows.medium)
                }
                .padding(ModernTheme.Spacing.lg)
            }
            .navigationTitle("Edit Education")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        education = editedEducation
                        dismiss()
                    }
                    .foregroundColor(ModernTheme.Colors.primarySolid)
                }
            }
        }
    }
}

#Preview {
    EducationEditView()
        .environmentObject(DataManager.shared)
}