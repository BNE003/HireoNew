//
//  ProfileView.swift
//  Hireo
//
//  Created by Benedikt Held on 19.08.25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var dataManager: DataManager
    @State private var showingProfileEdit = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let profile = dataManager.userProfile {
                        ProfileSummaryView(profile: profile)
                        
                        VStack(spacing: 15) {
                            ProfileSectionCard(
                                title: "Personal Information",
                                icon: "person.fill",
                                count: 1
                            )
                            
                            ProfileSectionCard(
                                title: "Education",
                                icon: "graduationcap.fill",
                                count: profile.education.count
                            )
                            
                            ProfileSectionCard(
                                title: "Work Experience",
                                icon: "briefcase.fill",
                                count: profile.workExperience.count
                            )
                            
                            ProfileSectionCard(
                                title: "Skills",
                                icon: "star.fill",
                                count: profile.skills.reduce(0) { $0 + $1.skills.count }
                            )
                            
                            ProfileSectionCard(
                                title: "Projects",
                                icon: "folder.fill",
                                count: profile.projects.count
                            )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(NSLocalizedString("profile", comment: ""))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("edit", comment: "")) {
                        showingProfileEdit = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingProfileEdit) {
            ProfileEditView()
        }
    }
}

struct ProfileSummaryView: View {
    let profile: UserProfile
    
    var body: some View {
        VStack(spacing: 15) {
            if let imageData = profile.personalInfo.profileImageData,
               let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.gray)
            }
            
            VStack(spacing: 5) {
                Text("\(profile.personalInfo.firstName) \(profile.personalInfo.lastName)")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if !profile.personalInfo.title.isEmpty {
                    Text(profile.personalInfo.title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .cardStyle()
    }
}

struct ProfileSectionCard: View {
    let title: String
    let icon: String
    let count: Int
    
    var body: some View {
        Button(action: {
            // TODO: Navigate to section edit
        }) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 24)
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .buttonStyle(.plain)
        .cardStyle()
    }
}

#Preview {
    NavigationStack {
        ProfileView()
            .environmentObject(DataManager.shared)
    }
}