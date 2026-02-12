//
//  DataManager.swift
//  Hireo
//
//  Created by Benedikt Held on 19.08.25.
//

import Foundation

@MainActor
class DataManager: ObservableObject {
    static let shared = DataManager()
    
    @Published var userProfile: UserProfile?
    @Published var applications: [Application] = []
    @Published var cvTemplates: [CVTemplate] = []
    @Published var coverLetterTemplates: [CoverLetterTemplate] = []
    @Published var cvDocuments: [CVDocument] = []
    @Published var coverLetterDocuments: [CoverLetterDocument] = []
    
    private let fileManager = FileManager.default
    private let documentsDirectory: URL
    
    private init() {
        self.documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        setupDirectories()
        loadBuiltInTemplates()
        loadAllData()
    }
    
    private func setupDirectories() {
        let directories = [
            "Applications",
            "Documents/CV",
            "Documents/CoverLetters",
            "Templates",
            "Exports"
        ]
        
        for directory in directories {
            let url = documentsDirectory.appendingPathComponent(directory)
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
    
    // MARK: - User Profile Management
    
    func saveUserProfile(_ profile: UserProfile) {
        do {
            let data = try JSONEncoder().encode(profile)
            let url = documentsDirectory.appendingPathComponent("user_profile.json")
            try data.write(to: url)
            self.userProfile = profile
        } catch {
            print("Failed to save user profile: \(error)")
        }
    }
    
    func loadUserProfile() -> UserProfile? {
        let url = documentsDirectory.appendingPathComponent("user_profile.json")
        
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        
        do {
            let profile = try JSONDecoder().decode(UserProfile.self, from: data)
            self.userProfile = profile
            return profile
        } catch {
            print("Failed to load user profile: \(error)")
            return nil
        }
    }
    
    // MARK: - Application Management
    
    func saveApplication(_ application: Application) {
        do {
            let data = try JSONEncoder().encode(application)
            let url = documentsDirectory.appendingPathComponent("Applications/\(application.id.uuidString).json")
            try data.write(to: url)
            
            if let index = applications.firstIndex(where: { $0.id == application.id }) {
                applications[index] = application
            } else {
                applications.append(application)
            }
        } catch {
            print("Failed to save application: \(error)")
        }
    }
    
    func loadApplications() {
        let applicationsDir = documentsDirectory.appendingPathComponent("Applications")
        
        guard let files = try? fileManager.contentsOfDirectory(at: applicationsDir, includingPropertiesForKeys: nil) else {
            return
        }
        
        var loadedApplications: [Application] = []
        
        for file in files where file.pathExtension == "json" {
            guard let data = try? Data(contentsOf: file),
                  let application = try? JSONDecoder().decode(Application.self, from: data) else {
                continue
            }
            loadedApplications.append(application)
        }
        
        self.applications = loadedApplications.sorted { $0.lastModified > $1.lastModified }
    }
    
    func deleteApplication(_ application: Application) {
        let url = documentsDirectory.appendingPathComponent("Applications/\(application.id.uuidString).json")
        try? fileManager.removeItem(at: url)
        applications.removeAll { $0.id == application.id }
    }
    
    // MARK: - Template Management
    
    func loadBuiltInTemplates() {
        cvTemplates = [
            CVTemplate(id: "modern", name: "Modern", description: "Clean and contemporary design", category: .modern),
            {
                var template = CVTemplate(
                    id: "modern_edge",
                    name: "Modern Edge",
                    description: "Contemporary split layout with bold cyan accents",
                    category: .modern
                )
                template.colorSchemes = [.teal, .blue, .black, .gray]
                template.fontFamilies = [.modern, .system, .serif]
                return template
            }(),
            {
                var template = CVTemplate(
                    id: "modern_aqua",
                    name: "Modern Aqua",
                    description: "Clean two-column layout with aqua sidebar and bold typography",
                    category: .modern
                )
                template.colorSchemes = [.teal, .gray, .blue, .black]
                template.fontFamilies = [.modern, .system, .serif]
                return template
            }(),
            {
                var template = CVTemplate(
                    id: "modern_ocean",
                    name: "Modern Ocean",
                    description: "Professional CV with right blue sidebar and clean work timeline",
                    category: .modern
                )
                template.colorSchemes = [.blue, .teal, .gray, .black]
                template.fontFamilies = [.modern, .system, .serif]
                return template
            }(),
            {
                var template = CVTemplate(
                    id: "modern_grid",
                    name: "Modern Grid",
                    description: "Structured editorial layout with boxed header and timeline-free experience sections",
                    category: .modern
                )
                template.colorSchemes = [.gray, .black, .blue]
                template.fontFamilies = [.modern, .system, .serif]
                return template
            }(),
            {
                var template = CVTemplate(
                    id: "modern_slate",
                    name: "Modern Slate",
                    description: "Studio-inspired resume with a slate hero header and editorial sidebar",
                    category: .modern
                )
                template.colorSchemes = [.gray, .black, .blue]
                template.fontFamilies = [.modern, .system, .serif]
                return template
            }(),
            {
                var template = CVTemplate(
                    id: "modern_mono",
                    name: "Modern Mono",
                    description: "Editorial two-column CV with bold typography and neutral palette",
                    category: .professional
                )
                template.colorSchemes = [.gray, .black, .blue]
                template.fontFamilies = [.modern, .system]
                return template
            }(),
            CVTemplate(id: "classic", name: "Classic", description: "Traditional professional layout", category: .classic),
            CVTemplate(id: "creative", name: "Creative", description: "Bold and eye-catching design", category: .creative),
            CVTemplate(id: "professional", name: "Professional", description: "Elegant two-column layout with modern styling", category: .professional),
            CVTemplate(id: "minimal", name: "Minimal", description: "Simple and focused layout", category: .minimal)
        ]
        
        coverLetterTemplates = [
            CoverLetterTemplate(id: "professional", name: "Professional", description: "Standard business format", category: .professional),
            CoverLetterTemplate(id: "modern", name: "Modern", description: "Contemporary design", category: .modern),
            {
                var template = CoverLetterTemplate(
                    id: "modern_mono_letter",
                    name: "Modern Mono",
                    description: "Matching editorial cover letter with clean left panel and bold title",
                    category: .professional
                )
                template.colorSchemes = [.gray, .black, .blue]
                template.fontFamilies = [.modern, .system, .serif]
                return template
            }(),
            {
                var template = CoverLetterTemplate(
                    id: "modern_editorial",
                    name: "Modern Editorial",
                    description: "Editorial one-page cover letter with profile hero and side recipient panel",
                    category: .modern
                )
                template.colorSchemes = [.gray, .black, .orange]
                template.fontFamilies = [.modern, .system, .serif]
                return template
            }(),
            {
                var template = CoverLetterTemplate(
                    id: "modern_guided_letter",
                    name: "Modern Guided",
                    description: "Structured modern cover letter with guided writing sections and clean accent layout",
                    category: .modern
                )
                template.colorSchemes = [.blue, .teal, .black, .gray]
                template.fontFamilies = [.modern, .system, .serif]
                return template
            }(),
            CoverLetterTemplate(id: "classic", name: "Classic", description: "Traditional format", category: .classic)
        ]
    }
    
    func getCVTemplate(by id: String) -> CVTemplate? {
        return cvTemplates.first { $0.id == id }
    }
    
    func getCoverLetterTemplate(by id: String) -> CoverLetterTemplate? {
        return coverLetterTemplates.first { $0.id == id }
    }
    
    // MARK: - Document Management
    
    func saveCVDocument(_ document: CVDocument) {
        do {
            let data = try JSONEncoder().encode(document)
            let url = documentsDirectory.appendingPathComponent("Documents/CV/\(document.id.uuidString).json")
            try data.write(to: url)
            
            if let index = cvDocuments.firstIndex(where: { $0.id == document.id }) {
                cvDocuments[index] = document
            } else {
                cvDocuments.append(document)
            }
            
            // Re-sort to ensure newest documents appear first
            cvDocuments.sort { $0.lastModified > $1.lastModified }
        } catch {
            print("Failed to save CV document: \(error)")
        }
    }
    
    func saveCoverLetterDocument(_ document: CoverLetterDocument) {
        do {
            let data = try JSONEncoder().encode(document)
            let url = documentsDirectory.appendingPathComponent("Documents/CoverLetters/\(document.id.uuidString).json")
            try data.write(to: url)
            
            if let index = coverLetterDocuments.firstIndex(where: { $0.id == document.id }) {
                coverLetterDocuments[index] = document
            } else {
                coverLetterDocuments.append(document)
            }
            
            // Re-sort to ensure newest documents appear first
            coverLetterDocuments.sort { $0.lastModified > $1.lastModified }
        } catch {
            print("Failed to save cover letter document: \(error)")
        }
    }
    
    func loadCVDocuments() {
        let cvDocsDir = documentsDirectory.appendingPathComponent("Documents/CV")
        
        guard let files = try? fileManager.contentsOfDirectory(at: cvDocsDir, includingPropertiesForKeys: nil) else {
            return
        }
        
        var loadedDocuments: [CVDocument] = []
        
        for file in files where file.pathExtension == "json" {
            guard let data = try? Data(contentsOf: file),
                  let document = try? JSONDecoder().decode(CVDocument.self, from: data) else {
                continue
            }
            loadedDocuments.append(document)
        }
        
        self.cvDocuments = loadedDocuments.sorted { $0.lastModified > $1.lastModified }
    }
    
    func loadCoverLetterDocuments() {
        let coverLetterDocsDir = documentsDirectory.appendingPathComponent("Documents/CoverLetters")
        
        guard let files = try? fileManager.contentsOfDirectory(at: coverLetterDocsDir, includingPropertiesForKeys: nil) else {
            return
        }
        
        var loadedDocuments: [CoverLetterDocument] = []
        
        for file in files where file.pathExtension == "json" {
            guard let data = try? Data(contentsOf: file),
                  let document = try? JSONDecoder().decode(CoverLetterDocument.self, from: data) else {
                continue
            }
            loadedDocuments.append(document)
        }
        
        self.coverLetterDocuments = loadedDocuments.sorted { $0.lastModified > $1.lastModified }
    }
    
    func deleteCVDocument(_ document: CVDocument) {
        let url = documentsDirectory.appendingPathComponent("Documents/CV/\(document.id.uuidString).json")
        try? fileManager.removeItem(at: url)
        cvDocuments.removeAll { $0.id == document.id }
    }
    
    func deleteCoverLetterDocument(_ document: CoverLetterDocument) {
        let url = documentsDirectory.appendingPathComponent("Documents/CoverLetters/\(document.id.uuidString).json")
        try? fileManager.removeItem(at: url)
        coverLetterDocuments.removeAll { $0.id == document.id }
    }
    
    // MARK: - Export Management
    
    func saveExportedPDF(_ data: Data, fileName: String) -> URL? {
        let url = documentsDirectory.appendingPathComponent("Exports/\(fileName)")
        
        do {
            try data.write(to: url)
            return url
        } catch {
            print("Failed to save exported PDF: \(error)")
            return nil
        }
    }
    
    func getExportsDirectory() -> URL {
        return documentsDirectory.appendingPathComponent("Exports")
    }
    
    // MARK: - Data Loading
    
    private func loadAllData() {
        _ = loadUserProfile()
        loadApplications()
        loadCVDocuments()
        loadCoverLetterDocuments()
    }
    
    // MARK: - Utility Methods
    
    func hasUserProfile() -> Bool {
        return userProfile != nil
    }
    
    func createNewApplication(companyName: String, position: String) -> Application {
        let application = Application(companyName: companyName, position: position)
        saveApplication(application)
        return application
    }
    
    func createNewCVDocument(templateId: String = "modern", for application: Application? = nil) -> CVDocument? {
        guard let userProfile = userProfile else { return nil }
        
        let document = CVDocument(
            userProfileId: userProfile.id,
            applicationId: application?.id,
            templateId: templateId
        )
        saveCVDocument(document)
        return document
    }
    
    func createNewCoverLetterDocument(templateId: String = "professional", for application: Application? = nil) -> CoverLetterDocument? {
        guard let userProfile = userProfile else { return nil }
        
        let document = CoverLetterDocument(
            userProfileId: userProfile.id,
            applicationId: application?.id,
            templateId: templateId
        )
        saveCoverLetterDocument(document)
        return document
    }
}
