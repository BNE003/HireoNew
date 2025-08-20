//
//  ModernCVTemplateView.swift
//  Hireo
//
//  Created by Benedikt Held on 20.08.25.
//

import SwiftUI
import PDFKit

struct ModernCVTemplateView: View {
    let userProfile: UserProfile
    let colorScheme: ColorScheme
    let fontFamily: FontFamily
    
    private let sidebarWidth: CGFloat = 280
    private let contentPadding: CGFloat = 30
    private let sectionSpacing: CGFloat = 25
    
    var body: some View {
        HStack(spacing: 0) {
            // Left Sidebar
            leftSidebar
                .frame(width: sidebarWidth)
                .background(Color(hex: "#3B3B3B"))
            
            // Right Content Area
            rightContentArea
                .frame(maxWidth: .infinity)
                .background(Color.white)
        }
        .frame(width: 595, height: 842) // A4 size in points
    }
    
    private var leftSidebar: some View {
        VStack(spacing: 0) {
            // Profile Picture Section
            VStack(spacing: 15) {
                profilePictureView
                    .padding(.top, contentPadding)
                
                // About Me Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 16))
                        Text("About Me")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Text(userProfile.personalInfo.summary.isEmpty ? 
                         "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam pharetra in lorem at laoreet. Donec hendrerit libero eget est tempor, quis tempus arcu elementum." : 
                         userProfile.personalInfo.summary)
                        .font(.system(size: 11))
                        .foregroundColor(.white)
                        .lineSpacing(2)
                }
                .padding(.horizontal, contentPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Spacer(minLength: 25)
            
            // Contact Section
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Image(systemName: "person.crop.rectangle.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                    Text("Contact")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    ContactRow(icon: "phone.fill", text: userProfile.personalInfo.phone.isEmpty ? "+123-456-7890" : userProfile.personalInfo.phone)
                    ContactRow(icon: "envelope.fill", text: userProfile.personalInfo.email.isEmpty ? "hello@reallygreatsite.com" : userProfile.personalInfo.email)
                    ContactRow(icon: "location.fill", text: formatAddress())
                }
            }
            .padding(.horizontal, contentPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer(minLength: 25)
            
            // Skills Section
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Image(systemName: "gear.circle.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                    Text("Skills")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(getSkillsList(), id: \.self) { skill in
                        HStack {
                            Circle()
                                .fill(.white)
                                .frame(width: 4, height: 4)
                            Text(skill)
                                .font(.system(size: 11))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .padding(.horizontal, contentPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer(minLength: 25)
            
            // Language Section
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Image(systemName: "textformat.abc")
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                    Text("Language")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(getLanguagesList(), id: \.self) { language in
                        HStack {
                            Circle()
                                .fill(.white)
                                .frame(width: 4, height: 4)
                            Text(language)
                                .font(.system(size: 11))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .padding(.horizontal, contentPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
        }
    }
    
    private var profilePictureView: some View {
        VStack {
            if let profileImageData = userProfile.personalInfo.profileImageData,
               let uiImage = UIImage(data: profileImageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 140, height: 140)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 6)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.black, lineWidth: 3)
                    )
            } else {
                // Default profile picture placeholder
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 140, height: 140)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 6)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.black, lineWidth: 3)
                    )
            }
        }
    }
    
    private var rightContentArea: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with name and title
            VStack(alignment: .trailing, spacing: 8) {
                Text(userProfile.personalInfo.firstName.isEmpty && userProfile.personalInfo.lastName.isEmpty ? 
                     "Isabel Schumacher" : "\(userProfile.personalInfo.firstName) \(userProfile.personalInfo.lastName)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                
                Text(userProfile.personalInfo.title.isEmpty ? "Graphics Designer" : userProfile.personalInfo.title)
                    .font(.system(size: 18))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.top, 40)
            .padding(.horizontal, contentPadding)
            
            Spacer(minLength: 40)
            
            // Education Section
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Image(systemName: "graduationcap.fill")
                        .foregroundColor(.black)
                        .font(.system(size: 20))
                    Text("Education")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.black)
                }
                
                VStack(alignment: .leading, spacing: 25) {
                    ForEach(getEducationEntries()) { entry in
                        EducationTimelineItem(entry: entry)
                    }
                }
            }
            .padding(.horizontal, contentPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer(minLength: 40)
            
            // Experience Section
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Image(systemName: "briefcase.fill")
                        .foregroundColor(.black)
                        .font(.system(size: 20))
                    Text("Experience")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.black)
                }
                
                VStack(alignment: .leading, spacing: 25) {
                    ForEach(getWorkExperienceEntries()) { entry in
                        ExperienceTimelineItem(entry: entry)
                    }
                }
            }
            .padding(.horizontal, contentPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
        }
    }
    
    private func formatAddress() -> String {
        let address = userProfile.personalInfo.address
        if address.street.isEmpty && address.city.isEmpty {
            return "123 Anywhere Street., Any City."
        }
        return "\(address.street), \(address.city)"
    }
    
    private func getSkillsList() -> [String] {
        let allSkills = userProfile.skills.flatMap { category in
            category.skills.map { $0.name }
        }
        
        if allSkills.isEmpty {
            return ["Web Design", "Branding", "Graphic Design", "SEO", "Marketing"]
        }
        
        return Array(allSkills.prefix(5))
    }
    
    private func getLanguagesList() -> [String] {
        if userProfile.languages.isEmpty {
            return ["English", "French"]
        }
        
        return userProfile.languages.map { $0.name }
    }
    
    private func getEducationEntries() -> [EducationDisplayEntry] {
        if userProfile.education.isEmpty {
            return [
                EducationDisplayEntry(
                    id: UUID(),
                    dateRange: "(2011 -2015)",
                    institution: "WARDIERE UNIVERSITY",
                    degree: "Bachelor of Design",
                    grade: "3.65"
                ),
                EducationDisplayEntry(
                    id: UUID(),
                    dateRange: "(2014 -2019)",
                    institution: "WARDIERE UNIVERSITY",
                    degree: "Bachelor of Design",
                    grade: "3.74"
                )
            ]
        }
        
        return userProfile.education.map { entry in
            let startYear = Calendar.current.component(.year, from: entry.startDate)
            let endYear = entry.endDate != nil ? Calendar.current.component(.year, from: entry.endDate!) : startYear
            let dateRange = "(\(startYear) -\(endYear))"
            
            return EducationDisplayEntry(
                id: entry.id,
                dateRange: dateRange,
                institution: entry.institution.uppercased(),
                degree: entry.degree,
                grade: entry.grade
            )
        }
    }
    
    private func getWorkExperienceEntries() -> [ExperienceDisplayEntry] {
        if userProfile.workExperience.isEmpty {
            return [
                ExperienceDisplayEntry(
                    id: UUID(),
                    dateRange: "(2020 -2023)",
                    position: "SENIOR GRAPHIC DESIGNER",
                    company: "Fauget studio",
                    achievements: [
                        "create more than 100 graphic designs for big companies",
                        "complete a lot of complicated work"
                    ]
                ),
                ExperienceDisplayEntry(
                    id: UUID(),
                    dateRange: "(2017 - 2019)",
                    position: "SENIOR GRAPHIC DESIGNER",
                    company: "larana, inc",
                    achievements: [
                        "create more than 100 graphic designs for big companies",
                        "complete a lot of complicated work"
                    ]
                )
            ]
        }
        
        return userProfile.workExperience.map { entry in
            let startYear = Calendar.current.component(.year, from: entry.startDate)
            let endYear = entry.endDate != nil ? Calendar.current.component(.year, from: entry.endDate!) : startYear
            let dateRange = "(\(startYear) - \(endYear))"
            
            return ExperienceDisplayEntry(
                id: entry.id,
                dateRange: dateRange,
                position: entry.position.uppercased(),
                company: entry.company,
                achievements: entry.achievements.isEmpty ? 
                    [entry.description] : 
                    entry.achievements
            )
        }
    }
}

struct ContactRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.white)
                .font(.system(size: 12))
                .frame(width: 16)
            
            Text(text)
                .font(.system(size: 11))
                .foregroundColor(.white)
        }
    }
}

struct EducationTimelineItem: View {
    let entry: EducationDisplayEntry
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            // Timeline dot and line
            VStack(spacing: 0) {
                Circle()
                    .fill(.black)
                    .frame(width: 8, height: 8)
                
                Rectangle()
                    .fill(.black)
                    .frame(width: 2, height: 40)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.dateRange)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.black)
                
                Text(entry.institution)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)
                
                Text(entry.degree)
                    .font(.system(size: 12))
                    .foregroundColor(.black)
                
                if !entry.grade.isEmpty {
                    Text(entry.grade)
                        .font(.system(size: 12))
                        .foregroundColor(.black)
                }
            }
            
            Spacer()
        }
    }
}

struct ExperienceTimelineItem: View {
    let entry: ExperienceDisplayEntry
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            // Timeline dot and line
            VStack(spacing: 0) {
                Circle()
                    .fill(.black)
                    .frame(width: 8, height: 8)
                
                Rectangle()
                    .fill(.black)
                    .frame(width: 2, height: 60)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.dateRange)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.black)
                
                Text(entry.position)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)
                
                Text(entry.company)
                    .font(.system(size: 12))
                    .foregroundColor(.black)
                
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(entry.achievements.prefix(2), id: \.self) { achievement in
                        HStack(alignment: .top, spacing: 5) {
                            Circle()
                                .fill(.black)
                                .frame(width: 3, height: 3)
                                .padding(.top, 5)
                            
                            Text(achievement)
                                .font(.system(size: 11))
                                .foregroundColor(.black)
                        }
                    }
                }
                .padding(.top, 2)
            }
            
            Spacer()
        }
    }
}

#Preview {
    ModernCVTemplateView(
        userProfile: UserProfile(),
        colorScheme: .black,
        fontFamily: .system
    )
}