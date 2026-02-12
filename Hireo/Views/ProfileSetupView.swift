//
//  ProfileSetupView.swift
//  Hireo
//
//  Created by Benedikt Held on 19.08.25.
//

import SwiftUI

struct ProfileSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataManager: DataManager
    @State private var userProfile = UserProfile()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Create Your Profile")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("Let's start with some basic information")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Form {
                    Section("Personal Information") {
                        TextField("First Name", text: $userProfile.personalInfo.firstName)
                        TextField("Last Name", text: $userProfile.personalInfo.lastName)
                        TextField("Job Title", text: $userProfile.personalInfo.title)
                        TextField("Email", text: $userProfile.personalInfo.email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }

                    Section("About Me") {
                        TextField("Professional Summary", text: $userProfile.personalInfo.summary, axis: .vertical)
                            .lineLimit(3...6)
                    }
                    
                    Section("Address") {
                        TextField("Street", text: $userProfile.personalInfo.address.street)
                        TextField("City", text: $userProfile.personalInfo.address.city)
                        TextField("Postal Code", text: $userProfile.personalInfo.address.postalCode)
                        TextField("Country", text: $userProfile.personalInfo.address.country)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button(action: saveProfile) {
                        Text("Create Profile")
                    }
                    .legacyPrimaryButton(isEnabled: canSave)
                    
                    Button("Skip for Now") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var canSave: Bool {
        !userProfile.personalInfo.firstName.isEmpty &&
        !userProfile.personalInfo.lastName.isEmpty
    }
    
    private func saveProfile() {
        dataManager.saveUserProfile(userProfile)
        dismiss()
    }
}

#Preview {
    ProfileSetupView()
        .environmentObject(DataManager.shared)
}
