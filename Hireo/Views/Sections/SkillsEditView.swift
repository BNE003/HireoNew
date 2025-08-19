//
//  SkillsEditView.swift
//  Hireo
//
//  Created by Benedikt Held on 19.08.25.
//

import SwiftUI

struct SkillsEditView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataManager: DataManager
    @State private var skillCategories: [SkillCategory]
    @State private var showingAddCategory = false
    
    init() {
        let skills = DataManager.shared.userProfile?.skills ?? []
        _skillCategories = State(initialValue: skills)
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    // Background
                    LinearGradient(
                        colors: [
                            ModernTheme.Colors.surface,
                            Color.purple.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    
                    ScrollView {
                        LazyVStack(spacing: ModernTheme.Spacing.lg) {
                            // Header
                            VStack(spacing: ModernTheme.Spacing.sm) {
                                Image(systemName: "star.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.purple)
                                
                                Text("Skills & Expertise")
                                    .font(ModernTheme.Typography.displaySmall)
                                    .foregroundColor(ModernTheme.Colors.textPrimary)
                                
                                Text("Showcase your technical and soft skills")
                                    .font(ModernTheme.Typography.bodyMedium)
                                    .foregroundColor(ModernTheme.Colors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, ModernTheme.Spacing.lg)
                            
                            // Skill Categories
                            if skillCategories.isEmpty {
                                EmptySkillsView {
                                    showingAddCategory = true
                                }
                            } else {
                                ForEach(skillCategories.indices, id: \.self) { categoryIndex in
                                    SkillCategoryCard(
                                        category: $skillCategories[categoryIndex],
                                        onDelete: {
                                            deleteCategory(at: categoryIndex)
                                        }
                                    )
                                    .padding(.horizontal, ModernTheme.Spacing.lg)
                                }
                            }
                            
                            // Add Category Button
                            Button(action: {
                                showingAddCategory = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Skill Category")
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
            .navigationTitle("Skills")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSkills()
                    }
                    .foregroundColor(ModernTheme.Colors.primarySolid)
                }
            }
        }
        .sheet(isPresented: $showingAddCategory) {
            AddSkillCategoryView { newCategory in
                skillCategories.append(newCategory)
            }
        }
    }
    
    private func deleteCategory(at index: Int) {
        withAnimation(ModernTheme.Animations.smooth) {
            skillCategories.remove(at: index)
        }
    }
    
    private func saveSkills() {
        guard var profile = dataManager.userProfile else { return }
        profile.skills = skillCategories
        dataManager.saveUserProfile(profile)
        dismiss()
    }
}

struct EmptySkillsView: View {
    let onAdd: () -> Void
    
    var body: some View {
        VStack(spacing: ModernTheme.Spacing.lg) {
            Image(systemName: "star.badge.plus")
                .font(.system(size: 80))
                .foregroundColor(Color.purple.opacity(0.3))
            
            VStack(spacing: ModernTheme.Spacing.sm) {
                Text("No Skills Added")
                    .font(ModernTheme.Typography.headingMedium)
                    .foregroundColor(ModernTheme.Colors.textPrimary)
                
                Text("Add your technical and soft skills organized by categories")
                    .font(ModernTheme.Typography.bodyMedium)
                    .foregroundColor(ModernTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Add Your First Skill Category") {
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

struct SkillCategoryCard: View {
    @Binding var category: SkillCategory
    let onDelete: () -> Void
    @State private var showingEdit = false
    @State private var showingAddSkill = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: ModernTheme.Spacing.md) {
            // Category Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.categoryName)
                        .font(ModernTheme.Typography.headingSmall)
                        .foregroundColor(ModernTheme.Colors.textPrimary)
                    
                    Text("\(category.skills.count) skill\(category.skills.count != 1 ? "s" : "")")
                        .font(ModernTheme.Typography.bodySmall)
                        .foregroundColor(ModernTheme.Colors.textSecondary)
                }
                
                Spacer()
                
                Button(action: {
                    showingAddSkill = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(ModernTheme.Colors.primarySolid)
                }
                
                Menu {
                    Button("Edit Category", systemImage: "pencil") {
                        showingEdit = true
                    }
                    
                    Button("Delete Category", systemImage: "trash", role: .destructive) {
                        onDelete()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title2)
                        .foregroundColor(ModernTheme.Colors.textSecondary)
                }
            }
            
            // Skills Grid
            if !category.skills.isEmpty {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: ModernTheme.Spacing.sm) {
                    ForEach(category.skills.indices, id: \.self) { skillIndex in
                        SkillChip(
                            skill: category.skills[skillIndex],
                            onDelete: {
                                category.skills.remove(at: skillIndex)
                            }
                        )
                    }
                }
            } else {
                Text("No skills in this category")
                    .font(ModernTheme.Typography.bodySmall)
                    .foregroundColor(ModernTheme.Colors.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, ModernTheme.Spacing.lg)
            }
        }
        .modernCard(shadow: ModernTheme.Shadows.small)
        .sheet(isPresented: $showingEdit) {
            EditSkillCategoryView(category: $category)
        }
        .sheet(isPresented: $showingAddSkill) {
            AddSkillView { newSkill in
                category.skills.append(newSkill)
            }
        }
    }
}

struct SkillChip: View {
    let skill: Skill
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: ModernTheme.Spacing.xs) {
            VStack(alignment: .leading, spacing: 2) {
                Text(skill.name)
                    .font(ModernTheme.Typography.labelMedium)
                    .foregroundColor(ModernTheme.Colors.textPrimary)
                
                HStack(spacing: 2) {
                    ForEach(0..<4, id: \.self) { index in
                        Circle()
                            .fill(index < proficiencyLevel ? Color.purple : ModernTheme.Colors.border)
                            .frame(width: 4, height: 4)
                    }
                    
                    Text(skill.proficiencyLevel.rawValue)
                        .font(.system(size: 9))
                        .foregroundColor(ModernTheme.Colors.textSecondary)
                }
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(ModernTheme.Colors.textTertiary)
            }
        }
        .padding(ModernTheme.Spacing.sm)
        .background(Color.purple.opacity(0.1))
        .cornerRadius(ModernTheme.Radius.sm)
        .overlay(
            RoundedRectangle(cornerRadius: ModernTheme.Radius.sm)
                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var proficiencyLevel: Int {
        switch skill.proficiencyLevel {
        case .beginner: return 1
        case .intermediate: return 2
        case .advanced: return 3
        case .expert: return 4
        }
    }
}

struct AddSkillCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (SkillCategory) -> Void
    
    @State private var categoryName = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: ModernTheme.Spacing.xl) {
                VStack(spacing: ModernTheme.Spacing.sm) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.purple)
                    
                    Text("New Skill Category")
                        .font(ModernTheme.Typography.headingLarge)
                        .foregroundColor(ModernTheme.Colors.textPrimary)
                    
                    Text("Organize your skills by category")
                        .font(ModernTheme.Typography.bodyMedium)
                        .foregroundColor(ModernTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: ModernTheme.Spacing.md) {
                    ModernTextField(
                        title: "Category Name",
                        text: $categoryName,
                        placeholder: "e.g., Programming Languages, Design Tools",
                        validation: .required
                    )
                    
                    VStack(alignment: .leading, spacing: ModernTheme.Spacing.sm) {
                        Text("Suggested Categories")
                            .font(ModernTheme.Typography.labelLarge)
                            .foregroundColor(ModernTheme.Colors.textPrimary)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: ModernTheme.Spacing.xs) {
                            ForEach(suggestedCategories, id: \.self) { suggestion in
                                Button(suggestion) {
                                    categoryName = suggestion
                                }
                                .font(ModernTheme.Typography.bodySmall)
                                .padding(.horizontal, ModernTheme.Spacing.sm)
                                .padding(.vertical, ModernTheme.Spacing.xs)
                                .background(ModernTheme.Colors.primaryLight)
                                .foregroundColor(ModernTheme.Colors.primarySolid)
                                .cornerRadius(ModernTheme.Radius.sm)
                            }
                        }
                    }
                }
                .modernCard(shadow: ModernTheme.Shadows.medium)
                
                Spacer()
            }
            .padding(ModernTheme.Spacing.lg)
            .navigationTitle("Add Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let category = SkillCategory(categoryName: categoryName.trimmingCharacters(in: .whitespacesAndNewlines))
                        onSave(category)
                        dismiss()
                    }
                    .foregroundColor(ModernTheme.Colors.primarySolid)
                    .disabled(categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private let suggestedCategories = [
        "Programming Languages",
        "Design Tools",
        "Project Management",
        "Communication",
        "Leadership",
        "Data Analysis",
        "Marketing",
        "Languages"
    ]
}

struct AddSkillView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (Skill) -> Void
    
    @State private var skillName = ""
    @State private var proficiencyLevel: ProficiencyLevel = .intermediate
    
    var body: some View {
        NavigationStack {
            VStack(spacing: ModernTheme.Spacing.xl) {
                VStack(spacing: ModernTheme.Spacing.sm) {
                    Image(systemName: "star.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.purple)
                    
                    Text("Add Skill")
                        .font(ModernTheme.Typography.headingLarge)
                        .foregroundColor(ModernTheme.Colors.textPrimary)
                }
                
                VStack(spacing: ModernTheme.Spacing.lg) {
                    ModernTextField(
                        title: "Skill Name",
                        text: $skillName,
                        placeholder: "e.g., Swift, Photoshop, Leadership",
                        validation: .required
                    )
                    
                    VStack(alignment: .leading, spacing: ModernTheme.Spacing.md) {
                        Text("Proficiency Level")
                            .font(ModernTheme.Typography.headingSmall)
                            .foregroundColor(ModernTheme.Colors.textPrimary)
                        
                        ForEach(ProficiencyLevel.allCases, id: \.self) { level in
                            ProficiencyLevelRow(
                                level: level,
                                isSelected: proficiencyLevel == level
                            ) {
                                proficiencyLevel = level
                            }
                        }
                    }
                }
                .modernCard(shadow: ModernTheme.Shadows.medium)
                
                Spacer()
            }
            .padding(ModernTheme.Spacing.lg)
            .navigationTitle("Add Skill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let skill = Skill(
                            name: skillName.trimmingCharacters(in: .whitespacesAndNewlines),
                            proficiencyLevel: proficiencyLevel
                        )
                        onSave(skill)
                        dismiss()
                    }
                    .foregroundColor(ModernTheme.Colors.primarySolid)
                    .disabled(skillName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

struct ProficiencyLevelRow: View {
    let level: ProficiencyLevel
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: ModernTheme.Spacing.md) {
                // Level indicator
                HStack(spacing: 2) {
                    ForEach(0..<4, id: \.self) { index in
                        Circle()
                            .fill(index < levelValue ? Color.purple : ModernTheme.Colors.border)
                            .frame(width: 8, height: 8)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(level.rawValue)
                        .font(ModernTheme.Typography.bodyMedium)
                        .foregroundColor(ModernTheme.Colors.textPrimary)
                    
                    Text(levelDescription)
                        .font(ModernTheme.Typography.bodySmall)
                        .foregroundColor(ModernTheme.Colors.textSecondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.purple)
                }
            }
            .padding(ModernTheme.Spacing.md)
            .background(isSelected ? Color.purple.opacity(0.1) : Color.clear)
            .cornerRadius(ModernTheme.Radius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: ModernTheme.Radius.sm)
                    .stroke(isSelected ? Color.purple.opacity(0.3) : ModernTheme.Colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var levelValue: Int {
        switch level {
        case .beginner: return 1
        case .intermediate: return 2
        case .advanced: return 3
        case .expert: return 4
        }
    }
    
    private var levelDescription: String {
        switch level {
        case .beginner: return "Basic knowledge and understanding"
        case .intermediate: return "Some experience and confidence"
        case .advanced: return "Extensive experience and expertise"
        case .expert: return "Deep expertise and mastery"
        }
    }
}

struct EditSkillCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var category: SkillCategory
    @State private var editedName: String
    
    init(category: Binding<SkillCategory>) {
        self._category = category
        self._editedName = State(initialValue: category.wrappedValue.categoryName)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: ModernTheme.Spacing.xl) {
                ModernTextField(
                    title: "Category Name",
                    text: $editedName,
                    validation: .required
                )
                .modernCard(shadow: ModernTheme.Shadows.medium)
                
                Spacer()
            }
            .padding(ModernTheme.Spacing.lg)
            .navigationTitle("Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        category.categoryName = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
                        dismiss()
                    }
                    .foregroundColor(ModernTheme.Colors.primarySolid)
                    .disabled(editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    SkillsEditView()
        .environmentObject(DataManager.shared)
}