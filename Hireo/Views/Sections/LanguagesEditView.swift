//
//  LanguagesEditView.swift
//  Hireo
//
//  Created by Benedikt Held on 19.08.25.
//

import SwiftUI

struct LanguagesEditView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataManager: DataManager
    @State private var languages: [Language]
    @State private var showingAddLanguage = false
    
    init() {
        let langs = DataManager.shared.userProfile?.languages ?? []
        _languages = State(initialValue: langs)
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    // Background
                    LinearGradient(
                        colors: [
                            ModernTheme.Colors.surface,
                            Color.cyan.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    
                    ScrollView {
                        LazyVStack(spacing: ModernTheme.Spacing.lg) {
                            // Header
                            VStack(spacing: ModernTheme.Spacing.sm) {
                                Image(systemName: "globe.badge.chevron.backward")
                                    .font(.system(size: 60))
                                    .foregroundColor(.cyan)
                                
                                Text("Languages")
                                    .font(ModernTheme.Typography.displaySmall)
                                    .foregroundColor(ModernTheme.Colors.textPrimary)
                                
                                Text("Add languages you speak and your proficiency level")
                                    .font(ModernTheme.Typography.bodyMedium)
                                    .foregroundColor(ModernTheme.Colors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, ModernTheme.Spacing.lg)
                            
                            // Languages
                            if languages.isEmpty {
                                EmptyLanguagesView {
                                    showingAddLanguage = true
                                }
                            } else {
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: ModernTheme.Spacing.md) {
                                    ForEach(languages.indices, id: \.self) { index in
                                        LanguageCard(
                                            language: $languages[index],
                                            onDelete: {
                                                deleteLanguage(at: index)
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, ModernTheme.Spacing.lg)
                            }
                            
                            // Add Button
                            Button(action: {
                                showingAddLanguage = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Language")
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
            .navigationTitle("Languages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveLanguages()
                    }
                    .foregroundColor(ModernTheme.Colors.primarySolid)
                }
            }
        }
        .sheet(isPresented: $showingAddLanguage) {
            AddLanguageView { newLanguage in
                languages.append(newLanguage)
            }
        }
    }
    
    private func deleteLanguage(at index: Int) {
        withAnimation(ModernTheme.Animations.smooth) {
            languages.remove(at: index)
        }
    }
    
    private func saveLanguages() {
        guard var profile = dataManager.userProfile else { return }
        profile.languages = languages
        dataManager.saveUserProfile(profile)
        dismiss()
    }
}

struct EmptyLanguagesView: View {
    let onAdd: () -> Void
    
    var body: some View {
        VStack(spacing: ModernTheme.Spacing.lg) {
            Image(systemName: "globe.badge.plus")
                .font(.system(size: 80))
                .foregroundColor(Color.cyan.opacity(0.3))
            
            VStack(spacing: ModernTheme.Spacing.sm) {
                Text("No Languages Added")
                    .font(ModernTheme.Typography.headingMedium)
                    .foregroundColor(ModernTheme.Colors.textPrimary)
                
                Text("Add languages you speak to showcase your international capabilities")
                    .font(ModernTheme.Typography.bodyMedium)
                    .foregroundColor(ModernTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Add Your First Language") {
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

struct LanguageCard: View {
    @Binding var language: Language
    let onDelete: () -> Void
    @State private var showingEdit = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: ModernTheme.Spacing.sm) {
            // Header
            HStack {
                Text(language.name)
                    .font(ModernTheme.Typography.headingSmall)
                    .foregroundColor(ModernTheme.Colors.textPrimary)
                
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
                        .font(.title3)
                        .foregroundColor(ModernTheme.Colors.textSecondary)
                }
            }
            
            // Proficiency Level
            VStack(alignment: .leading, spacing: ModernTheme.Spacing.xs) {
                Text(language.proficiencyLevel.rawValue)
                    .font(ModernTheme.Typography.bodySmall)
                    .foregroundColor(.cyan)
                
                // Progress bar
                HStack(spacing: 2) {
                    ForEach(0..<6, id: \.self) { index in
                        Rectangle()
                            .fill(index < proficiencyValue ? Color.cyan : ModernTheme.Colors.border)
                            .frame(height: 4)
                            .cornerRadius(2)
                    }
                }
            }
        }
        .padding(ModernTheme.Spacing.md)
        .background(Color.cyan.opacity(0.05))
        .cornerRadius(ModernTheme.Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: ModernTheme.Radius.md)
                .stroke(Color.cyan.opacity(0.2), lineWidth: 1)
        )
        .sheet(isPresented: $showingEdit) {
            EditLanguageView(language: $language)
        }
    }
    
    private var proficiencyValue: Int {
        switch language.proficiencyLevel {
        case .elementary: return 1
        case .intermediate: return 2
        case .upperIntermediate: return 3
        case .advanced: return 4
        case .proficient: return 5
        case .native: return 6
        }
    }
}

struct AddLanguageView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (Language) -> Void
    
    @State private var languageName = ""
    @State private var proficiencyLevel: LanguageProficiency = .intermediate
    
    var body: some View {
        NavigationStack {
            VStack(spacing: ModernTheme.Spacing.xl) {
                VStack(spacing: ModernTheme.Spacing.sm) {
                    Image(systemName: "globe.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.cyan)
                    
                    Text("Add Language")
                        .font(ModernTheme.Typography.headingLarge)
                        .foregroundColor(ModernTheme.Colors.textPrimary)
                }
                
                VStack(spacing: ModernTheme.Spacing.lg) {
                    VStack(spacing: ModernTheme.Spacing.md) {
                        ModernTextField(
                            title: "Language",
                            text: $languageName,
                            placeholder: "e.g., English, Spanish, German",
                            validation: .required
                        )
                        
                        VStack(alignment: .leading, spacing: ModernTheme.Spacing.sm) {
                            Text("Suggested Languages")
                                .font(ModernTheme.Typography.labelLarge)
                                .foregroundColor(ModernTheme.Colors.textPrimary)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: ModernTheme.Spacing.xs) {
                                ForEach(suggestedLanguages, id: \.self) { suggestion in
                                    Button(suggestion) {
                                        languageName = suggestion
                                    }
                                    .font(ModernTheme.Typography.bodySmall)
                                    .padding(.horizontal, ModernTheme.Spacing.sm)
                                    .padding(.vertical, ModernTheme.Spacing.xs)
                                    .background(Color.cyan.opacity(0.1))
                                    .foregroundColor(.cyan)
                                    .cornerRadius(ModernTheme.Radius.sm)
                                }
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: ModernTheme.Spacing.md) {
                        Text("Proficiency Level")
                            .font(ModernTheme.Typography.headingSmall)
                            .foregroundColor(ModernTheme.Colors.textPrimary)
                        
                        ForEach(LanguageProficiency.allCases, id: \.self) { level in
                            LanguageProficiencyRow(
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
            .navigationTitle("Add Language")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let language = Language(
                            name: languageName.trimmingCharacters(in: .whitespacesAndNewlines),
                            proficiencyLevel: proficiencyLevel
                        )
                        onSave(language)
                        dismiss()
                    }
                    .foregroundColor(ModernTheme.Colors.primarySolid)
                    .disabled(languageName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private let suggestedLanguages = [
        "English", "Spanish", "French", "German", "Italian", "Portuguese",
        "Dutch", "Russian", "Chinese", "Japanese", "Korean", "Arabic"
    ]
}

struct LanguageProficiencyRow: View {
    let level: LanguageProficiency
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: ModernTheme.Spacing.md) {
                // Level indicator
                HStack(spacing: 2) {
                    ForEach(0..<6, id: \.self) { index in
                        Rectangle()
                            .fill(index < levelValue ? Color.cyan : ModernTheme.Colors.border)
                            .frame(width: 16, height: 4)
                            .cornerRadius(2)
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
                        .foregroundColor(.cyan)
                }
            }
            .padding(ModernTheme.Spacing.md)
            .background(isSelected ? Color.cyan.opacity(0.1) : Color.clear)
            .cornerRadius(ModernTheme.Radius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: ModernTheme.Radius.sm)
                    .stroke(isSelected ? Color.cyan.opacity(0.3) : ModernTheme.Colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var levelValue: Int {
        switch level {
        case .elementary: return 1
        case .intermediate: return 2
        case .upperIntermediate: return 3
        case .advanced: return 4
        case .proficient: return 5
        case .native: return 6
        }
    }
    
    private var levelDescription: String {
        switch level {
        case .elementary: return "Basic words and phrases"
        case .intermediate: return "Simple conversations"
        case .upperIntermediate: return "Comfortable in most situations"
        case .advanced: return "Fluent in complex topics"
        case .proficient: return "Near-native fluency"
        case .native: return "Native speaker"
        }
    }
}

struct EditLanguageView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var language: Language
    @State private var editedName: String
    @State private var editedLevel: LanguageProficiency
    
    init(language: Binding<Language>) {
        self._language = language
        self._editedName = State(initialValue: language.wrappedValue.name)
        self._editedLevel = State(initialValue: language.wrappedValue.proficiencyLevel)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: ModernTheme.Spacing.xl) {
                VStack(spacing: ModernTheme.Spacing.lg) {
                    ModernTextField(
                        title: "Language",
                        text: $editedName,
                        validation: .required
                    )
                    
                    VStack(alignment: .leading, spacing: ModernTheme.Spacing.md) {
                        Text("Proficiency Level")
                            .font(ModernTheme.Typography.headingSmall)
                            .foregroundColor(ModernTheme.Colors.textPrimary)
                        
                        ForEach(LanguageProficiency.allCases, id: \.self) { level in
                            LanguageProficiencyRow(
                                level: level,
                                isSelected: editedLevel == level
                            ) {
                                editedLevel = level
                            }
                        }
                    }
                }
                .modernCard(shadow: ModernTheme.Shadows.medium)
                
                Spacer()
            }
            .padding(ModernTheme.Spacing.lg)
            .navigationTitle("Edit Language")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        language.name = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
                        language.proficiencyLevel = editedLevel
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
    LanguagesEditView()
        .environmentObject(DataManager.shared)
}