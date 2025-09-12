//
//  TemplatesView.swift
//  Hireo
//
//  Created by Benedikt Held on 19.08.25.
//

import SwiftUI
import PDFKit


struct TemplatesView: View {
    @EnvironmentObject private var dataManager: DataManager
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Template Type", selection: $selectedTab) {
                    Text("CV Templates").tag(0)
                    Text("Cover Letters").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                TabView(selection: $selectedTab) {
                    CVTemplatesTab()
                        .tag(0)
                    
                    CoverLetterTemplatesTab()
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Templates")
        }
    }
}

struct CVTemplatesTab: View {
    @EnvironmentObject private var dataManager: DataManager
    @State private var selectedTemplate: CVTemplate?
    @State private var showingTemplateDetail = false
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(dataManager.cvTemplates) { template in
                    CVTemplateThumbnail(template: template) {
                        selectedTemplate = template
                        showingTemplateDetail = true
                    }
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingTemplateDetail) {
            if let template = selectedTemplate {
                CVTemplateDetailView(template: template)
            }
        }
    }
}

struct CoverLetterTemplatesTab: View {
    @EnvironmentObject private var dataManager: DataManager
    @State private var selectedTemplate: CoverLetterTemplate?
    @State private var showingTemplateDetail = false
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(dataManager.coverLetterTemplates) { template in
                    CoverLetterTemplateThumbnail(template: template) {
                        selectedTemplate = template
                        showingTemplateDetail = true
                    }
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingTemplateDetail) {
            if let template = selectedTemplate {
                CoverLetterTemplateDetailView(template: template)
            }
        }
    }
}

// MARK: - Thumbnail Views

struct CVTemplateThumbnail: View {
    let template: CVTemplate
    let onTap: () -> Void
    @EnvironmentObject private var dataManager: DataManager
    @State private var isGeneratingThumbnail = false
    @State private var thumbnailPDFData: Data?
    
    var body: some View {
        Button(action: onTap) {
            Group {
                if isGeneratingThumbnail {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                        .frame(height: 220)
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.8)
                        )
                } else if let thumbnailData = thumbnailPDFData {
                    PDFThumbnailView(pdfData: thumbnailData)
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                        .frame(height: 220)
                        .overlay(
                            Image(systemName: "doc.text")
                                .font(.system(size: 30))
                                .foregroundColor(Color(hex: template.colorSchemes.first?.primaryColor ?? "#007AFF"))
                        )
                }
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            generateThumbnail()
        }
    }
    
    private func generateThumbnail() {
        guard thumbnailPDFData == nil else { return }
        
        let dummyProfile = createDummyUserProfile()
        isGeneratingThumbnail = true
        
        Task {
            do {
                let pdfDocument = try await PDFGenerationService.shared.generateCV(
                    userProfile: dummyProfile,
                    template: template,
                    customSettings: CVSettings()
                )
                
                guard let pdfData = pdfDocument.dataRepresentation() else { return }
                
                await MainActor.run {
                    self.thumbnailPDFData = pdfData
                    self.isGeneratingThumbnail = false
                }
            } catch {
                await MainActor.run {
                    self.isGeneratingThumbnail = false
                }
            }
        }
    }
}

struct CoverLetterTemplateThumbnail: View {
    let template: CoverLetterTemplate
    let onTap: () -> Void
    @EnvironmentObject private var dataManager: DataManager
    @State private var isGeneratingThumbnail = false
    @State private var thumbnailPDFData: Data?
    
    var body: some View {
        Button(action: onTap) {
            Group {
                if isGeneratingThumbnail {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                        .frame(height: 220)
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.8)
                        )
                } else if let thumbnailData = thumbnailPDFData {
                    PDFThumbnailView(pdfData: thumbnailData)
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                        .frame(height: 220)
                        .overlay(
                            Image(systemName: "envelope")
                                .font(.system(size: 30))
                                .foregroundColor(Color(hex: template.colorSchemes.first?.primaryColor ?? "#34C759"))
                        )
                }
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            generateThumbnail()
        }
    }
    
    private func generateThumbnail() {
        guard thumbnailPDFData == nil else { return }
        
        let dummyProfile = createDummyUserProfile()
        isGeneratingThumbnail = true
        
        Task {
            do {
                let sampleContent = CoverLetterContent()
                
                let pdfDocument = try await PDFGenerationService.shared.generateCoverLetter(
                    userProfile: dummyProfile,
                    template: template,
                    content: sampleContent
                )
                
                guard let pdfData = pdfDocument.dataRepresentation() else { return }
                
                await MainActor.run {
                    self.thumbnailPDFData = pdfData
                    self.isGeneratingThumbnail = false
                }
            } catch {
                await MainActor.run {
                    self.isGeneratingThumbnail = false
                }
            }
        }
    }
}

// MARK: - Detail Views

struct CVTemplateDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataManager: DataManager
    let template: CVTemplate
    @State private var showingTemplateCustomization = false
    @State private var isGenerating = false
    @State private var previewPDFData: Data?
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var showingPDFPreview = false
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Large Preview
                    if let previewData = previewPDFData {
                        PDFPreviewContainer(pdfData: previewData)
                            .frame(height: geometry.size.height * 0.6)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal, 20)
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray6))
                            .frame(height: geometry.size.height * 0.6)
                            .overlay(
                                VStack(spacing: 16) {
                                    Image(systemName: "doc.text")
                                        .font(.system(size: 60, weight: .light))
                                        .foregroundColor(Color(hex: template.colorSchemes.first?.primaryColor ?? "#007AFF"))
                                    
                                    Text(template.name)
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    
                                    Text(template.description)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 40)
                                }
                            )
                            .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        Button(action: generateCV) {
                            HStack {
                                if isGenerating {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "arrow.down.doc.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                Text(isGenerating ? "Generating..." : "Generate CV")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(hex: template.colorSchemes.first?.primaryColor ?? "#007AFF"))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(isGenerating || dataManager.userProfile == nil)
                        
                        Button("Customize Template") {
                            showingTemplateCustomization = true
                        }
                        .font(.headline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .disabled(dataManager.userProfile == nil)
                        
                        if dataManager.userProfile == nil {
                            Text("Complete your profile first")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                                .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.headline)
                    .fontWeight(.medium)
                }
            }
        }
        .sheet(isPresented: $showingTemplateCustomization) {
            CVTemplateCustomizationView(template: template)
        }
        .sheet(isPresented: $showingPDFPreview) {
            if let pdfData = previewPDFData {
                PDFPreviewView(pdfData: pdfData, title: "\(template.name) CV")
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
        .onAppear {
            generatePreview()
        }
    }
    
    private func generatePreview() {
        let userProfile = dataManager.userProfile ?? createDummyUserProfile()
        
        Task {
            do {
                let pdfDocument = try await PDFGenerationService.shared.generateCV(
                    userProfile: userProfile,
                    template: template,
                    customSettings: CVSettings()
                )
                
                guard let pdfData = pdfDocument.dataRepresentation() else { return }
                
                await MainActor.run {
                    self.previewPDFData = pdfData
                }
            } catch {
                // Preview generation failed, but continue without preview
            }
        }
    }
    
    private func generateCV() {
        guard let userProfile = dataManager.userProfile else { return }
        
        isGenerating = true
        
        Task {
            do {
                let pdfDocument = try await PDFGenerationService.shared.generateCV(
                    userProfile: userProfile,
                    template: template,
                    customSettings: CVSettings()
                )
                
                guard let pdfData = pdfDocument.dataRepresentation() else {
                    throw PDFGenerationError.renderingFailed("Failed to get PDF data")
                }
                
                await MainActor.run {
                    self.previewPDFData = pdfData
                    self.showingPDFPreview = true
                    self.isGenerating = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showingError = true
                    self.isGenerating = false
                }
            }
        }
    }
}

struct CoverLetterTemplateDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataManager: DataManager
    let template: CoverLetterTemplate
    @State private var showingTemplateCustomization = false
    @State private var isGenerating = false
    @State private var previewPDFData: Data?
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var showingPDFPreview = false
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Large Preview
                    if let previewData = previewPDFData {
                        PDFPreviewContainer(pdfData: previewData)
                            .frame(height: geometry.size.height * 0.6)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal, 20)
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray6))
                            .frame(height: geometry.size.height * 0.6)
                            .overlay(
                                VStack(spacing: 16) {
                                    Image(systemName: "envelope")
                                        .font(.system(size: 60, weight: .light))
                                        .foregroundColor(Color(hex: template.colorSchemes.first?.primaryColor ?? "#34C759"))
                                    
                                    Text(template.name)
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    
                                    Text(template.description)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 40)
                                }
                            )
                            .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        Button(action: generateCoverLetter) {
                            HStack {
                                if isGenerating {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "arrow.down.doc.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                Text(isGenerating ? "Generating..." : "Generate Cover Letter")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(hex: template.colorSchemes.first?.primaryColor ?? "#34C759"))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(isGenerating || dataManager.userProfile == nil)
                        
                        Button("Customize Template") {
                            showingTemplateCustomization = true
                        }
                        .font(.headline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .disabled(dataManager.userProfile == nil)
                        
                        if dataManager.userProfile == nil {
                            Text("Complete your profile first")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                                .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.headline)
                    .fontWeight(.medium)
                }
            }
        }
        .sheet(isPresented: $showingTemplateCustomization) {
            CoverLetterTemplateCustomizationView(template: template)
        }
        .sheet(isPresented: $showingPDFPreview) {
            if let pdfData = previewPDFData {
                PDFPreviewView(pdfData: pdfData, title: "\(template.name) Cover Letter")
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
        .onAppear {
            generatePreview()
        }
    }
    
    private func generatePreview() {
        let userProfile = dataManager.userProfile ?? createDummyUserProfile()
        
        Task {
            do {
                let sampleContent = CoverLetterContent()
                
                let pdfDocument = try await PDFGenerationService.shared.generateCoverLetter(
                    userProfile: userProfile,
                    template: template,
                    content: sampleContent
                )
                
                guard let pdfData = pdfDocument.dataRepresentation() else { return }
                
                await MainActor.run {
                    self.previewPDFData = pdfData
                }
            } catch {
                // Preview generation failed, but continue without preview
            }
        }
    }
    
    private func generateCoverLetter() {
        guard let userProfile = dataManager.userProfile else { return }
        
        isGenerating = true
        
        Task {
            do {
                let sampleContent = CoverLetterContent()
                
                let pdfDocument = try await PDFGenerationService.shared.generateCoverLetter(
                    userProfile: userProfile,
                    template: template,
                    content: sampleContent
                )
                
                guard let pdfData = pdfDocument.dataRepresentation() else {
                    throw PDFGenerationError.renderingFailed("Failed to get PDF data")
                }
                
                await MainActor.run {
                    self.previewPDFData = pdfData
                    self.showingPDFPreview = true
                    self.isGenerating = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showingError = true
                    self.isGenerating = false
                }
            }
        }
    }
}

// MARK: - Helper Views

struct PDFThumbnailView: UIViewRepresentable {
    let pdfData: Data
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.systemBackground
        
        guard let pdfDocument = PDFDocument(data: pdfData),
              let page = pdfDocument.page(at: 0) else {
            return view
        }
        
        let pageFrame = page.bounds(for: .mediaBox)
        let scaleFactor: CGFloat = 120 / max(pageFrame.width, pageFrame.height)
        
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        DispatchQueue.global(qos: .userInitiated).async {
            let targetSize = CGSize(width: pageFrame.width * scaleFactor, height: pageFrame.height * scaleFactor)
            let renderer = UIGraphicsImageRenderer(size: targetSize)
            
            let image = renderer.image { context in
                let cgContext = context.cgContext
                
                // Fill with white background
                cgContext.setFillColor(UIColor.white.cgColor)
                cgContext.fill(CGRect(origin: .zero, size: targetSize))
                
                // Save the current context state
                cgContext.saveGState()
                
                // Transform coordinate system to match PDF coordinate system
                cgContext.translateBy(x: 0, y: targetSize.height)
                cgContext.scaleBy(x: scaleFactor, y: -scaleFactor)
                
                // Draw the PDF page
                page.draw(with: .mediaBox, to: cgContext)
                
                // Restore the context state
                cgContext.restoreGState()
            }
            
            DispatchQueue.main.async {
                imageView.image = image
            }
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

struct PDFPreviewContainer: UIViewRepresentable {
    let pdfData: Data
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(data: pdfData)
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .vertical
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {}
}

// MARK: - Helper Functions

func createDummyUserProfile() -> UserProfile {
    var profile = UserProfile()
    
    profile.personalInfo.firstName = "John"
    profile.personalInfo.lastName = "Doe" 
    profile.personalInfo.title = "Software Engineer"
    profile.personalInfo.email = "john.doe@example.com"
    profile.personalInfo.phone = "+1 (555) 123-4567"
    profile.personalInfo.summary = "Experienced software engineer with expertise in iOS development and modern app architecture. Passionate about creating user-friendly applications."
    
    profile.personalInfo.address.street = "123 Tech Street"
    profile.personalInfo.address.city = "San Francisco"
    profile.personalInfo.address.postalCode = "94105"
    profile.personalInfo.address.country = "United States"
    
    var workExp1 = WorkExperienceEntry()
    workExp1.position = "Senior iOS Developer"
    workExp1.company = "Tech Corp"
    workExp1.startDate = Date().addingTimeInterval(-365*24*60*60*2) // 2 years ago
    workExp1.endDate = nil
    workExp1.isCurrentJob = true
    workExp1.description = "Lead iOS development for flagship mobile application with 1M+ users. Implemented new features and maintained code quality."
    workExp1.achievements = [
        "Increased app performance by 30%",
        "Led migration to SwiftUI architecture"
    ]
    
    var workExp2 = WorkExperienceEntry()
    workExp2.position = "iOS Developer"
    workExp2.company = "StartupXYZ"
    workExp2.startDate = Date().addingTimeInterval(-365*24*60*60*4) // 4 years ago
    workExp2.endDate = Date().addingTimeInterval(-365*24*60*60*2) // 2 years ago
    workExp2.isCurrentJob = false
    workExp2.description = "Built iOS applications from ground up and contributed to product development."
    workExp2.achievements = [
        "Delivered 3 successful app launches",
        "Reduced crash rate by 50%"
    ]
    
    profile.workExperience = [workExp1, workExp2]
    
    var education = EducationEntry()
    education.institution = "University of Technology"
    education.degree = "Bachelor of Science"
    education.fieldOfStudy = "Computer Science"
    education.startDate = Date().addingTimeInterval(-365*24*60*60*8) // 8 years ago
    education.endDate = Date().addingTimeInterval(-365*24*60*60*4) // 4 years ago
    education.isCurrentlyStudying = false
    education.grade = "3.8 GPA"
    education.description = "Focused on software engineering and mobile development."
    
    profile.education = [education]
    
    var programmingCategory = SkillCategory(categoryName: "Programming Languages")
    programmingCategory.skills = [
        Skill(name: "Swift", proficiencyLevel: .expert),
        Skill(name: "Objective-C", proficiencyLevel: .advanced),
        Skill(name: "Python", proficiencyLevel: .intermediate),
        Skill(name: "JavaScript", proficiencyLevel: .intermediate)
    ]
    
    var frameworksCategory = SkillCategory(categoryName: "Frameworks & Tools")
    frameworksCategory.skills = [
        Skill(name: "SwiftUI", proficiencyLevel: .expert),
        Skill(name: "UIKit", proficiencyLevel: .expert),
        Skill(name: "Xcode", proficiencyLevel: .expert),
        Skill(name: "Git", proficiencyLevel: .advanced)
    ]
    
    profile.skills = [programmingCategory, frameworksCategory]
    
    var project = Project()
    project.name = "TaskMaster Pro"
    project.description = "A productivity app for task management with advanced scheduling features."
    project.technologies = ["Swift", "SwiftUI", "Core Data"]
    project.startDate = Date().addingTimeInterval(-365*24*60*60*1) // 1 year ago
    project.endDate = Date().addingTimeInterval(-365*24*60*60*0.5) // 6 months ago
    project.isOngoing = false
    project.url = "https://github.com/johndoe/taskmaster"
    
    profile.projects = [project]
    
    var certificate = Certificate()
    certificate.name = "iOS App Development with Swift"
    certificate.issuingOrganization = "Apple"
    certificate.issueDate = Date().addingTimeInterval(-365*24*60*60*1) // 1 year ago
    certificate.expirationDate = nil
    certificate.credentialId = "APPL-iOS-2023"
    
    profile.certificates = [certificate]
    
    profile.languages = [
        Language(name: "English", proficiencyLevel: .native),
        Language(name: "Spanish", proficiencyLevel: .intermediate)
    ]
    
    profile.interests = ["iOS Development", "UI/UX Design", "Machine Learning", "Photography"]
    
    return profile
}

#Preview {
    NavigationStack {
        TemplatesView()
            .environmentObject(DataManager.shared)
    }
}