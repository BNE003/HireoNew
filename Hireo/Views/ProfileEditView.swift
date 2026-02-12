//
//  ProfileEditView.swift
//  Hireo
//
//  Created by Benedikt Held on 19.08.25.
//

import SwiftUI

struct ProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataManager: DataManager
    @State private var personalInfo: PersonalInfo
    
    init() {
        _personalInfo = State(initialValue: DataManager.shared.userProfile?.personalInfo ?? PersonalInfo())
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Information") {
                    TextField("First Name", text: $personalInfo.firstName)
                    TextField("Last Name", text: $personalInfo.lastName)
                    TextField("Job Title", text: $personalInfo.title)
                    TextField("Email", text: $personalInfo.email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Phone", text: $personalInfo.phone)
                        .keyboardType(.phonePad)
                }
                
                Section("Address") {
                    TextField("Street", text: $personalInfo.address.street)
                    TextField("City", text: $personalInfo.address.city)
                    TextField("Postal Code", text: $personalInfo.address.postalCode)
                    TextField("Country", text: $personalInfo.address.country)
                }
                
                Section("Additional Sections") {
                    NavigationLink("Education (\(currentProfile.education.count))") {
                        EducationEditView()
                    }
                    
                    NavigationLink("Work Experience (\(currentProfile.workExperience.count))") {
                        WorkExperienceEditView()
                    }
                    
                    NavigationLink("Skills (\(skillsCount))") {
                        SkillsEditView()
                    }
                    
                    NavigationLink("Languages (\(currentProfile.languages.count))") {
                        LanguagesEditView()
                    }
                    
                    NavigationLink("Projects (\(currentProfile.projects.count))") {
                        Text("Projects editing coming soon")
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let profile = dataManager.userProfile {
                    personalInfo = profile.personalInfo
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var currentProfile: UserProfile {
        dataManager.userProfile ?? UserProfile()
    }
    
    private var skillsCount: Int {
        currentProfile.skills.reduce(0) { $0 + $1.skills.count }
    }
    
    private func saveProfile() {
        var profile = dataManager.userProfile ?? UserProfile()
        profile.personalInfo = personalInfo
        profile.lastUpdated = Date()
        dataManager.saveUserProfile(profile)
    }
}

#Preview {
    ProfileEditView()
        .environmentObject(DataManager.shared)
}
