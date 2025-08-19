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
    @State private var userProfile: UserProfile
    
    init() {
        _userProfile = State(initialValue: DataManager.shared.userProfile ?? UserProfile())
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Information") {
                    TextField("First Name", text: $userProfile.personalInfo.firstName)
                    TextField("Last Name", text: $userProfile.personalInfo.lastName)
                    TextField("Job Title", text: $userProfile.personalInfo.title)
                    TextField("Email", text: $userProfile.personalInfo.email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Phone", text: $userProfile.personalInfo.phone)
                        .keyboardType(.phonePad)
                }
                
                Section("Address") {
                    TextField("Street", text: $userProfile.personalInfo.address.street)
                    TextField("City", text: $userProfile.personalInfo.address.city)
                    TextField("Postal Code", text: $userProfile.personalInfo.address.postalCode)
                    TextField("Country", text: $userProfile.personalInfo.address.country)
                }
                
                Section("Additional Sections") {
                    NavigationLink("Education (\(userProfile.education.count))") {
                        Text("Education editing coming soon")
                    }
                    
                    NavigationLink("Work Experience (\(userProfile.workExperience.count))") {
                        Text("Work experience editing coming soon")
                    }
                    
                    NavigationLink("Skills") {
                        Text("Skills editing coming soon")
                    }
                    
                    NavigationLink("Projects (\(userProfile.projects.count))") {
                        Text("Projects editing coming soon")
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        dataManager.saveUserProfile(userProfile)
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ProfileEditView()
        .environmentObject(DataManager.shared)
}