//
//  PDFGenerationService.swift
//  Hireo
//
//  Created by Benedikt Held on 19.08.25.
//

import Foundation
import PDFKit
import UIKit
import SwiftUI

class PDFGenerationService: ObservableObject {
    static let shared = PDFGenerationService()
    
    // DIN A4 Format - 210 × 297 mm = 595.28 × 841.89 points (rounded to 595 × 842)
    // Used consistently across all PDF templates (Classic, Modern, Creative, Cover Letter)
    static let dinA4Size = CGSize(width: 595, height: 842)
    static let dinA4Rect = CGRect(origin: .zero, size: dinA4Size)
    
    private init() {}
    
    func generateCV(
        userProfile: UserProfile,
        template: CVTemplate,
        customSettings: CVSettings? = nil
    ) async throws -> PDFDocument {
        let settings = customSettings ?? CVSettings()
        let renderer = CVPDFRenderer(
            userProfile: userProfile,
            template: template,
            settings: settings
        )
        
        return try await renderer.generatePDF()
    }
    
    func generateCoverLetter(
        userProfile: UserProfile,
        template: CoverLetterTemplate,
        content: CoverLetterContent
    ) async throws -> PDFDocument {
        let renderer = CoverLetterPDFRenderer(
            userProfile: userProfile,
            template: template,
            content: content
        )
        
        return try await renderer.generatePDF()
    }
    
    func savePDFToDocuments(_ pdfDocument: PDFDocument, fileName: String) throws -> URL {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw PDFGenerationError.fileSystemError("Could not access documents directory")
        }
        
        let fileURL = documentsPath.appendingPathComponent("\(fileName).pdf")
        pdfDocument.write(to: fileURL)
        
        return fileURL
    }
}

enum PDFGenerationError: LocalizedError {
    case templateNotFound
    case invalidUserData
    case renderingFailed(String)
    case fileSystemError(String)
    
    var errorDescription: String? {
        switch self {
        case .templateNotFound:
            return NSLocalizedString("pdf.error.template_not_found", comment: "")
        case .invalidUserData:
            return NSLocalizedString("pdf.error.invalid_user_data", comment: "")
        case .renderingFailed(let message):
            return NSLocalizedString("pdf.error.rendering_failed", comment: "") + ": \(message)"
        case .fileSystemError(let message):
            return NSLocalizedString("pdf.error.file_system", comment: "") + ": \(message)"
        }
    }
}

protocol PDFRenderer {
    func generatePDF() async throws -> PDFDocument
}

class CVPDFRenderer: PDFRenderer {
    let userProfile: UserProfile
    let template: CVTemplate
    let settings: CVSettings
    
    init(userProfile: UserProfile, template: CVTemplate, settings: CVSettings) {
        self.userProfile = userProfile
        self.template = template
        self.settings = settings
    }
    
    func generatePDF() async throws -> PDFDocument {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                do {
                    // Check template category to use appropriate renderer
                    if self.template.category == .classic {
                        let classicRenderer = ClassicTemplatePDFRenderer(
                            userProfile: self.userProfile,
                            template: self.template,
                            settings: self.settings
                        )
                        let pdfDocument = try classicRenderer.generatePDF()
                        continuation.resume(returning: pdfDocument)
                    } else if self.template.category == .modern {
                        let modernRenderer = ModernTemplatePDFRenderer(
                            userProfile: self.userProfile,
                            template: self.template,
                            settings: self.settings
                        )
                        let pdfDocument = try modernRenderer.generatePDF()
                        continuation.resume(returning: pdfDocument)
                    } else if self.template.category == .creative {
                        let creativeRenderer = CreativeTemplatePDFRenderer(
                            userProfile: self.userProfile,
                            template: self.template,
                            settings: self.settings
                        )
                        let pdfDocument = try creativeRenderer.generatePDF()
                        continuation.resume(returning: pdfDocument)
                    } else if self.template.category == .professional {
                        let professionalRenderer = ProfessionalTemplatePDFRenderer(
                            userProfile: self.userProfile,
                            template: self.template,
                            settings: self.settings
                        )
                        let pdfDocument = try professionalRenderer.generatePDF()
                        continuation.resume(returning: pdfDocument)
                    } else {
                        // Keep existing logic for other templates
                        let pdfRenderer = self.createPDFRenderer()
                        let pdfDocument = PDFDocument()
                        
                        let pageCount = self.calculatePageCount()
                        for pageIndex in 0..<pageCount {
                            let pageRect = PDFGenerationService.dinA4Rect
                            let page = PDFPage()
                            
                            let pageContent = self.renderPage(pageIndex: pageIndex, in: pageRect)
                            page.setBounds(pageRect, for: .mediaBox)
                            
                            pdfDocument.insert(page, at: pageIndex)
                        }
                        
                        continuation.resume(returning: pdfDocument)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func createPDFRenderer() -> UIGraphicsPDFRenderer {
        let renderer = UIGraphicsPDFRenderer(bounds: PDFGenerationService.dinA4Rect)
        return renderer
    }
    
    private func calculatePageCount() -> Int {
        let contentHeight = estimateContentHeight()
        let pageHeight: CGFloat = PDFGenerationService.dinA4Size.height - 80 // A4 height minus margins (40 top + 40 bottom)
        return max(1, Int(ceil(contentHeight / pageHeight)))
    }
    
    private func estimateContentHeight() -> CGFloat {
        var totalHeight: CGFloat = 0
        
        // Header
        totalHeight += 120
        
        // Each section
        for section in settings.sectionOrder {
            if settings.includedSections.contains(section) {
                switch section {
                case .personalInfo:
                    totalHeight += 60
                case .summary:
                    totalHeight += 80
                case .workExperience:
                    totalHeight += CGFloat(userProfile.workExperience.count * 80 + 40)
                case .education:
                    totalHeight += CGFloat(userProfile.education.count * 60 + 40)
                case .skills:
                    totalHeight += CGFloat(userProfile.skills.count * 40 + 40)
                case .projects:
                    totalHeight += CGFloat(userProfile.projects.count * 70 + 40)
                case .certificates:
                    totalHeight += CGFloat(userProfile.certificates.count * 50 + 40)
                case .languages:
                    totalHeight += CGFloat(userProfile.languages.count * 30 + 40)
                case .interests:
                    totalHeight += 60
                }
            }
        }
        
        return totalHeight
    }
    
    private func renderPage(pageIndex: Int, in rect: CGRect) -> UIView {
        let pageView = UIView(frame: rect)
        pageView.backgroundColor = .white
        
        if pageIndex == 0 {
            // Render header on first page
            renderHeader(in: pageView)
        }
        
        // Render content sections
        renderSections(in: pageView, pageIndex: pageIndex)
        
        return pageView
    }
    
    private func renderHeader(in containerView: UIView) {
        let headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(headerView)
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 40),
            headerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 40),
            headerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -40),
            headerView.heightAnchor.constraint(equalToConstant: 120)
        ])
        
        // Name
        let nameLabel = UILabel()
        nameLabel.text = "\(userProfile.personalInfo.firstName) \(userProfile.personalInfo.lastName)"
        nameLabel.font = UIFont.boldSystemFont(ofSize: 28)
        nameLabel.textColor = UIColor(hex: template.colorSchemes.first?.primaryColor ?? "#007AFF")
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(nameLabel)
        
        // Title
        let titleLabel = UILabel()
        titleLabel.text = userProfile.personalInfo.title
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = .darkGray
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)
        
        // Contact info
        let contactStack = UIStackView()
        contactStack.axis = .horizontal
        contactStack.spacing = 20
        contactStack.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(contactStack)
        
        let emailLabel = UILabel()
        emailLabel.text = userProfile.personalInfo.email
        emailLabel.font = UIFont.systemFont(ofSize: 12)
        emailLabel.textColor = .darkGray
        contactStack.addArrangedSubview(emailLabel)
        
        let phoneLabel = UILabel()
        phoneLabel.text = userProfile.personalInfo.phone
        phoneLabel.font = UIFont.systemFont(ofSize: 12)
        phoneLabel.textColor = .darkGray
        contactStack.addArrangedSubview(phoneLabel)
        
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: headerView.topAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 5),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            
            contactStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 15),
            contactStack.leadingAnchor.constraint(equalTo: headerView.leadingAnchor)
        ])
    }
    
    private func renderSections(in containerView: UIView, pageIndex: Int) {
        var currentY: CGFloat = pageIndex == 0 ? 200 : 40
        
        for section in settings.sectionOrder {
            if settings.includedSections.contains(section) {
                currentY += renderSection(section, in: containerView, at: currentY)
            }
        }
    }
    
    private func renderSection(_ section: CVSection, in containerView: UIView, at yPosition: CGFloat) -> CGFloat {
        let sectionView = UIView()
        sectionView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(sectionView)
        
        NSLayoutConstraint.activate([
            sectionView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: yPosition),
            sectionView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 40),
            sectionView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -40)
        ])
        
        // Section title
        let titleLabel = UILabel()
        titleLabel.text = section.localizedString.uppercased()
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textColor = UIColor(hex: template.colorSchemes.first?.primaryColor ?? "#007AFF")
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        sectionView.addSubview(titleLabel)
        
        var contentHeight: CGFloat = 30
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: sectionView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: sectionView.leadingAnchor)
        ])
        
        // Render section content based on type
        switch section {
        case .workExperience:
            contentHeight += renderWorkExperience(in: sectionView, startingAt: 30)
        case .education:
            contentHeight += renderEducation(in: sectionView, startingAt: 30)
        case .skills:
            contentHeight += renderSkills(in: sectionView, startingAt: 30)
        case .projects:
            contentHeight += renderProjects(in: sectionView, startingAt: 30)
        case .certificates:
            contentHeight += renderCertificates(in: sectionView, startingAt: 30)
        case .languages:
            contentHeight += renderLanguages(in: sectionView, startingAt: 30)
        default:
            contentHeight += 20
        }
        
        sectionView.heightAnchor.constraint(equalToConstant: contentHeight).isActive = true
        
        return contentHeight + 20 // Add spacing between sections
    }
    
    private func renderWorkExperience(in containerView: UIView, startingAt yOffset: CGFloat) -> CGFloat {
        var currentY = yOffset
        
        for experience in userProfile.workExperience {
            let entryView = createWorkExperienceEntry(experience)
            entryView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(entryView)
            
            NSLayoutConstraint.activate([
                entryView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: currentY),
                entryView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                entryView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                entryView.heightAnchor.constraint(equalToConstant: 80)
            ])
            
            currentY += 80
        }
        
        return currentY - yOffset
    }
    
    private func renderEducation(in containerView: UIView, startingAt yOffset: CGFloat) -> CGFloat {
        var currentY = yOffset
        
        for education in userProfile.education {
            let entryView = createEducationEntry(education)
            entryView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(entryView)
            
            NSLayoutConstraint.activate([
                entryView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: currentY),
                entryView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                entryView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                entryView.heightAnchor.constraint(equalToConstant: 60)
            ])
            
            currentY += 60
        }
        
        return currentY - yOffset
    }
    
    private func renderSkills(in containerView: UIView, startingAt yOffset: CGFloat) -> CGFloat {
        var currentY = yOffset
        
        for skillCategory in userProfile.skills {
            let categoryView = createSkillCategoryEntry(skillCategory)
            categoryView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(categoryView)
            
            NSLayoutConstraint.activate([
                categoryView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: currentY),
                categoryView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                categoryView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                categoryView.heightAnchor.constraint(equalToConstant: 40)
            ])
            
            currentY += 40
        }
        
        return currentY - yOffset
    }
    
    private func renderProjects(in containerView: UIView, startingAt yOffset: CGFloat) -> CGFloat {
        var currentY = yOffset
        
        for project in userProfile.projects {
            let projectView = createProjectEntry(project)
            projectView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(projectView)
            
            NSLayoutConstraint.activate([
                projectView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: currentY),
                projectView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                projectView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                projectView.heightAnchor.constraint(equalToConstant: 70)
            ])
            
            currentY += 70
        }
        
        return currentY - yOffset
    }
    
    private func renderCertificates(in containerView: UIView, startingAt yOffset: CGFloat) -> CGFloat {
        var currentY = yOffset
        
        for certificate in userProfile.certificates {
            let certView = createCertificateEntry(certificate)
            certView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(certView)
            
            NSLayoutConstraint.activate([
                certView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: currentY),
                certView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                certView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                certView.heightAnchor.constraint(equalToConstant: 50)
            ])
            
            currentY += 50
        }
        
        return currentY - yOffset
    }
    
    private func renderLanguages(in containerView: UIView, startingAt yOffset: CGFloat) -> CGFloat {
        var currentY = yOffset
        
        for language in userProfile.languages {
            let langView = createLanguageEntry(language)
            langView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(langView)
            
            NSLayoutConstraint.activate([
                langView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: currentY),
                langView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                langView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                langView.heightAnchor.constraint(equalToConstant: 30)
            ])
            
            currentY += 30
        }
        
        return currentY - yOffset
    }
    
    // Helper methods for creating entry views
    private func createWorkExperienceEntry(_ experience: WorkExperienceEntry) -> UIView {
        let container = UIView()
        
        let positionLabel = UILabel()
        positionLabel.text = experience.position
        positionLabel.font = UIFont.boldSystemFont(ofSize: 14)
        positionLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(positionLabel)
        
        let companyLabel = UILabel()
        companyLabel.text = experience.company
        companyLabel.font = UIFont.systemFont(ofSize: 12)
        companyLabel.textColor = .darkGray
        companyLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(companyLabel)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        let datesLabel = UILabel()
        let endDateText = experience.isCurrentJob ? "Present" : dateFormatter.string(from: experience.endDate ?? Date())
        datesLabel.text = "\(dateFormatter.string(from: experience.startDate)) - \(endDateText)"
        datesLabel.font = UIFont.systemFont(ofSize: 11)
        datesLabel.textColor = .gray
        datesLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(datesLabel)
        
        let descriptionLabel = UILabel()
        descriptionLabel.text = experience.description
        descriptionLabel.font = UIFont.systemFont(ofSize: 11)
        descriptionLabel.numberOfLines = 2
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(descriptionLabel)
        
        NSLayoutConstraint.activate([
            positionLabel.topAnchor.constraint(equalTo: container.topAnchor),
            positionLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            
            companyLabel.topAnchor.constraint(equalTo: positionLabel.bottomAnchor, constant: 2),
            companyLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            
            datesLabel.topAnchor.constraint(equalTo: container.topAnchor),
            datesLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            descriptionLabel.topAnchor.constraint(equalTo: companyLabel.bottomAnchor, constant: 5),
            descriptionLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])
        
        return container
    }
    
    private func createEducationEntry(_ education: EducationEntry) -> UIView {
        let container = UIView()
        
        let degreeLabel = UILabel()
        degreeLabel.text = "\(education.degree) in \(education.fieldOfStudy)"
        degreeLabel.font = UIFont.boldSystemFont(ofSize: 14)
        degreeLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(degreeLabel)
        
        let institutionLabel = UILabel()
        institutionLabel.text = education.institution
        institutionLabel.font = UIFont.systemFont(ofSize: 12)
        institutionLabel.textColor = .darkGray
        institutionLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(institutionLabel)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        let datesLabel = UILabel()
        let endDateText = education.isCurrentlyStudying ? "Present" : dateFormatter.string(from: education.endDate ?? Date())
        datesLabel.text = "\(dateFormatter.string(from: education.startDate)) - \(endDateText)"
        datesLabel.font = UIFont.systemFont(ofSize: 11)
        datesLabel.textColor = .gray
        datesLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(datesLabel)
        
        NSLayoutConstraint.activate([
            degreeLabel.topAnchor.constraint(equalTo: container.topAnchor),
            degreeLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            
            institutionLabel.topAnchor.constraint(equalTo: degreeLabel.bottomAnchor, constant: 2),
            institutionLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            
            datesLabel.topAnchor.constraint(equalTo: container.topAnchor),
            datesLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])
        
        return container
    }
    
    private func createSkillCategoryEntry(_ skillCategory: SkillCategory) -> UIView {
        let container = UIView()
        
        let categoryLabel = UILabel()
        categoryLabel.text = skillCategory.categoryName
        categoryLabel.font = UIFont.boldSystemFont(ofSize: 12)
        categoryLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(categoryLabel)
        
        let skillsLabel = UILabel()
        skillsLabel.text = skillCategory.skills.map { $0.name }.joined(separator: ", ")
        skillsLabel.font = UIFont.systemFont(ofSize: 11)
        skillsLabel.textColor = .darkGray
        skillsLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(skillsLabel)
        
        NSLayoutConstraint.activate([
            categoryLabel.topAnchor.constraint(equalTo: container.topAnchor),
            categoryLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            
            skillsLabel.topAnchor.constraint(equalTo: categoryLabel.bottomAnchor, constant: 2),
            skillsLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            skillsLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])
        
        return container
    }
    
    private func createProjectEntry(_ project: Project) -> UIView {
        let container = UIView()
        
        let nameLabel = UILabel()
        nameLabel.text = project.name
        nameLabel.font = UIFont.boldSystemFont(ofSize: 14)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(nameLabel)
        
        let descriptionLabel = UILabel()
        descriptionLabel.text = project.description
        descriptionLabel.font = UIFont.systemFont(ofSize: 11)
        descriptionLabel.numberOfLines = 2
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(descriptionLabel)
        
        let techLabel = UILabel()
        techLabel.text = "Technologies: \(project.technologies.joined(separator: ", "))"
        techLabel.font = UIFont.systemFont(ofSize: 10)
        techLabel.textColor = .gray
        techLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(techLabel)
        
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: container.topAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            
            descriptionLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            descriptionLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            techLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 2),
            techLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor)
        ])
        
        return container
    }
    
    private func createCertificateEntry(_ certificate: Certificate) -> UIView {
        let container = UIView()
        
        let nameLabel = UILabel()
        nameLabel.text = certificate.name
        nameLabel.font = UIFont.boldSystemFont(ofSize: 12)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(nameLabel)
        
        let orgLabel = UILabel()
        orgLabel.text = certificate.issuingOrganization
        orgLabel.font = UIFont.systemFont(ofSize: 11)
        orgLabel.textColor = .darkGray
        orgLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(orgLabel)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        let dateLabel = UILabel()
        dateLabel.text = dateFormatter.string(from: certificate.issueDate)
        dateLabel.font = UIFont.systemFont(ofSize: 10)
        dateLabel.textColor = .gray
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(dateLabel)
        
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: container.topAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            
            orgLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            orgLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            
            dateLabel.topAnchor.constraint(equalTo: container.topAnchor),
            dateLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])
        
        return container
    }
    
    private func createLanguageEntry(_ language: Language) -> UIView {
        let container = UIView()
        
        let nameLabel = UILabel()
        nameLabel.text = language.name
        nameLabel.font = UIFont.systemFont(ofSize: 12)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(nameLabel)
        
        let levelLabel = UILabel()
        levelLabel.text = language.proficiencyLevel.localizedString
        levelLabel.font = UIFont.systemFont(ofSize: 11)
        levelLabel.textColor = .darkGray
        levelLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(levelLabel)
        
        NSLayoutConstraint.activate([
            nameLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            
            levelLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            levelLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])
        
        return container
    }
}

class CoverLetterPDFRenderer: PDFRenderer {
    let userProfile: UserProfile
    let template: CoverLetterTemplate
    let content: CoverLetterContent
    
    init(userProfile: UserProfile, template: CoverLetterTemplate, content: CoverLetterContent) {
        self.userProfile = userProfile
        self.template = template
        self.content = content
    }
    
    func generatePDF() async throws -> PDFDocument {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                do {
                    let pageRect = PDFGenerationService.dinA4Rect
                    let margin: CGFloat = 40
                    let maxContentY = pageRect.height - margin - 50
                    
                    // Create PDF data
                    let pdfData = NSMutableData()
                    UIGraphicsBeginPDFContextToData(pdfData, pageRect, nil)
                    UIGraphicsBeginPDFPage()
                    
                    var currentY: CGFloat = margin
                    
                    // Draw header with sender info
                    currentY = self.drawSenderInfoDirect(at: CGPoint(x: margin, y: currentY), maxWidth: pageRect.width - 2 * margin)
                    currentY += 40
                    
                    // Draw date
                    currentY = self.drawDateDirect(at: CGPoint(x: margin, y: currentY), maxWidth: pageRect.width - 2 * margin)
                    currentY += 40
                    
                    // Draw recipient info
                    currentY = self.drawRecipientInfoDirect(at: CGPoint(x: margin, y: currentY), maxWidth: pageRect.width - 2 * margin)
                    currentY += 40
                    
                    // Draw content with page breaks
                    currentY = self.drawCoverLetterContentWithPageBreaks(at: currentY, maxWidth: pageRect.width - 2 * margin, maxContentY: maxContentY, margin: margin)
                    
                    UIGraphicsEndPDFContext()
                    
                    // Create PDFDocument from the generated data
                    guard let pdfDocument = PDFDocument(data: pdfData as Data) else {
                        throw PDFGenerationError.renderingFailed("Failed to create PDF document from data")
                    }
                    
                    continuation.resume(returning: pdfDocument)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func renderCoverLetter(in rect: CGRect) -> UIView {
        let pageView = UIView(frame: rect)
        pageView.backgroundColor = .white
        
        // Header with sender info
        renderSenderInfo(in: pageView)
        
        // Date
        renderDate(in: pageView)
        
        // Recipient info
        renderRecipientInfo(in: pageView)
        
        // Cover letter content
        renderContent(in: pageView)
        
        return pageView
    }
    
    private func renderSenderInfo(in containerView: UIView) {
        let senderView = UIView()
        senderView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(senderView)
        
        NSLayoutConstraint.activate([
            senderView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 40),
            senderView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 40),
            senderView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -40),
            senderView.heightAnchor.constraint(equalToConstant: 80)
        ])
        
        let nameLabel = UILabel()
        nameLabel.text = "\(userProfile.personalInfo.firstName) \(userProfile.personalInfo.lastName)"
        nameLabel.font = UIFont.boldSystemFont(ofSize: 16)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        senderView.addSubview(nameLabel)
        
        let addressLabel = UILabel()
        addressLabel.text = "\(userProfile.personalInfo.address.street)\n\(userProfile.personalInfo.address.postalCode) \(userProfile.personalInfo.address.city)"
        addressLabel.font = UIFont.systemFont(ofSize: 12)
        addressLabel.numberOfLines = 0
        addressLabel.translatesAutoresizingMaskIntoConstraints = false
        senderView.addSubview(addressLabel)
        
        let contactLabel = UILabel()
        contactLabel.text = "\(userProfile.personalInfo.email) | \(userProfile.personalInfo.phone)"
        contactLabel.font = UIFont.systemFont(ofSize: 12)
        contactLabel.translatesAutoresizingMaskIntoConstraints = false
        senderView.addSubview(contactLabel)
        
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: senderView.topAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: senderView.leadingAnchor),
            
            addressLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 5),
            addressLabel.leadingAnchor.constraint(equalTo: senderView.leadingAnchor),
            
            contactLabel.topAnchor.constraint(equalTo: addressLabel.bottomAnchor, constant: 5),
            contactLabel.leadingAnchor.constraint(equalTo: senderView.leadingAnchor)
        ])
    }
    
    // Direct drawing methods for multi-page support
    @discardableResult
    private func drawSenderInfoDirect(at point: CGPoint, maxWidth: CGFloat) -> CGFloat {
        var currentY = point.y
        
        // Name
        let fullName = "\(userProfile.personalInfo.firstName) \(userProfile.personalInfo.lastName)"
        let nameSize = drawTextDirect(fullName, at: CGPoint(x: point.x, y: currentY), font: UIFont.boldSystemFont(ofSize: 16), color: .black, maxWidth: maxWidth)
        currentY += nameSize.height + 5
        
        // Address
        let addressText = "\(userProfile.personalInfo.address.street)\n\(userProfile.personalInfo.address.postalCode) \(userProfile.personalInfo.address.city)"
        let addressSize = drawTextDirect(addressText, at: CGPoint(x: point.x, y: currentY), font: UIFont.systemFont(ofSize: 12), color: .black, maxWidth: maxWidth)
        currentY += addressSize.height + 5
        
        // Contact
        let contactText = "\(userProfile.personalInfo.email) | \(userProfile.personalInfo.phone)"
        let contactSize = drawTextDirect(contactText, at: CGPoint(x: point.x, y: currentY), font: UIFont.systemFont(ofSize: 12), color: .black, maxWidth: maxWidth)
        currentY += contactSize.height
        
        return currentY
    }
    
    @discardableResult
    private func drawDateDirect(at point: CGPoint, maxWidth: CGFloat) -> CGFloat {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        let dateText = formatter.string(from: Date())
        
        let dateSize = drawTextDirect(dateText, at: CGPoint(x: point.x + maxWidth - 200, y: point.y), font: UIFont.systemFont(ofSize: 12), color: .black, maxWidth: 200)
        return point.y + dateSize.height
    }
    
    @discardableResult
    private func drawRecipientInfoDirect(at point: CGPoint, maxWidth: CGFloat) -> CGFloat {
        var currentY = point.y
        
        // Recipient name (if available)
        if let recipientName = content.recipientName, !recipientName.isEmpty {
            let nameSize = drawTextDirect(recipientName, at: CGPoint(x: point.x, y: currentY), font: UIFont.systemFont(ofSize: 12), color: .black, maxWidth: maxWidth)
            currentY += nameSize.height + 5
        }
        
        // Company name
        let companySize = drawTextDirect(content.recipientCompany, at: CGPoint(x: point.x, y: currentY), font: UIFont.systemFont(ofSize: 12), color: .black, maxWidth: maxWidth)
        currentY += companySize.height
        
        return currentY
    }
    
    @discardableResult
    private func drawCoverLetterContentWithPageBreaks(at startY: CGFloat, maxWidth: CGFloat, maxContentY: CGFloat, margin: CGFloat) -> CGFloat {
        var currentY = startY
        
        // Salutation
        let salutationSize = drawTextDirect(content.salutation, at: CGPoint(x: margin, y: currentY), font: UIFont.systemFont(ofSize: 12), color: .black, maxWidth: maxWidth)
        currentY += salutationSize.height + 20
        
        // Introduction
        let introHeight = estimateTextHeightDirect(content.introduction, font: UIFont.systemFont(ofSize: 12), maxWidth: maxWidth)
        if currentY + introHeight > maxContentY {
            UIGraphicsBeginPDFPage()
            currentY = margin
        }
        
        let introSize = drawTextDirect(content.introduction, at: CGPoint(x: margin, y: currentY), font: UIFont.systemFont(ofSize: 12), color: .black, maxWidth: maxWidth)
        currentY += introSize.height + 20
        
        // Body
        let bodyHeight = estimateTextHeightDirect(content.body, font: UIFont.systemFont(ofSize: 12), maxWidth: maxWidth)
        if currentY + bodyHeight > maxContentY {
            UIGraphicsBeginPDFPage()
            currentY = margin
        }
        
        let bodySize = drawTextDirect(content.body, at: CGPoint(x: margin, y: currentY), font: UIFont.systemFont(ofSize: 12), color: .black, maxWidth: maxWidth)
        currentY += bodySize.height + 20
        
        // Closing
        if currentY + 60 > maxContentY {
            UIGraphicsBeginPDFPage()
            currentY = margin
        }
        
        let closingSize = drawTextDirect(content.closing, at: CGPoint(x: margin, y: currentY), font: UIFont.systemFont(ofSize: 12), color: .black, maxWidth: maxWidth)
        currentY += closingSize.height + 20
        
        // Signature
        let signatureSize = drawTextDirect(content.signature, at: CGPoint(x: margin, y: currentY), font: UIFont.systemFont(ofSize: 12), color: .black, maxWidth: maxWidth)
        currentY += signatureSize.height
        
        return currentY
    }
    
    @discardableResult
    private func drawTextDirect(_ text: String, at point: CGPoint, font: UIFont, color: UIColor, maxWidth: CGFloat) -> CGSize {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let constraintSize = CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude)
        let boundingRect = attributedString.boundingRect(with: constraintSize, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        
        let drawingRect = CGRect(origin: point, size: boundingRect.size)
        attributedString.draw(in: drawingRect)
        
        return boundingRect.size
    }
    
    private func estimateTextHeightDirect(_ text: String, font: UIFont, maxWidth: CGFloat) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let constraintSize = CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude)
        let boundingRect = attributedString.boundingRect(with: constraintSize, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        return boundingRect.height
    }
    
    private func renderDate(in containerView: UIView) {
        let dateLabel = UILabel()
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        dateLabel.text = formatter.string(from: Date())
        dateLabel.font = UIFont.systemFont(ofSize: 12)
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(dateLabel)
        
        NSLayoutConstraint.activate([
            dateLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 160),
            dateLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -40)
        ])
    }
    
    private func renderRecipientInfo(in containerView: UIView) {
        let recipientView = UIView()
        recipientView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(recipientView)
        
        NSLayoutConstraint.activate([
            recipientView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 200),
            recipientView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 40),
            recipientView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -40),
            recipientView.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        if let recipientName = content.recipientName, !recipientName.isEmpty {
            let nameLabel = UILabel()
            nameLabel.text = recipientName
            nameLabel.font = UIFont.systemFont(ofSize: 12)
            nameLabel.translatesAutoresizingMaskIntoConstraints = false
            recipientView.addSubview(nameLabel)
            
            NSLayoutConstraint.activate([
                nameLabel.topAnchor.constraint(equalTo: recipientView.topAnchor),
                nameLabel.leadingAnchor.constraint(equalTo: recipientView.leadingAnchor)
            ])
        }
        
        let companyLabel = UILabel()
        companyLabel.text = content.recipientCompany
        companyLabel.font = UIFont.systemFont(ofSize: 12)
        companyLabel.translatesAutoresizingMaskIntoConstraints = false
        recipientView.addSubview(companyLabel)
        
        NSLayoutConstraint.activate([
            companyLabel.topAnchor.constraint(equalTo: recipientView.topAnchor, constant: content.recipientName != nil ? 20 : 0),
            companyLabel.leadingAnchor.constraint(equalTo: recipientView.leadingAnchor)
        ])
    }
    
    private func renderContent(in containerView: UIView) {
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 300),
            contentView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 40),
            contentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -40),
            contentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -100)
        ])
        
        var currentY: CGFloat = 0
        
        // Salutation
        let salutationLabel = UILabel()
        salutationLabel.text = content.salutation
        salutationLabel.font = UIFont.systemFont(ofSize: 12)
        salutationLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(salutationLabel)
        
        NSLayoutConstraint.activate([
            salutationLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: currentY),
            salutationLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        ])
        currentY += 30
        
        // Introduction
        let introLabel = UILabel()
        introLabel.text = content.introduction
        introLabel.font = UIFont.systemFont(ofSize: 12)
        introLabel.numberOfLines = 0
        introLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(introLabel)
        
        NSLayoutConstraint.activate([
            introLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: currentY),
            introLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            introLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
        currentY += 80
        
        // Body
        let bodyLabel = UILabel()
        bodyLabel.text = content.body
        bodyLabel.font = UIFont.systemFont(ofSize: 12)
        bodyLabel.numberOfLines = 0
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bodyLabel)
        
        NSLayoutConstraint.activate([
            bodyLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: currentY),
            bodyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bodyLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
        currentY += 120
        
        // Closing
        let closingLabel = UILabel()
        closingLabel.text = content.closing
        closingLabel.font = UIFont.systemFont(ofSize: 12)
        closingLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(closingLabel)
        
        NSLayoutConstraint.activate([
            closingLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: currentY),
            closingLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        ])
        currentY += 40
        
        // Signature
        let signatureLabel = UILabel()
        signatureLabel.text = content.signature
        signatureLabel.font = UIFont.systemFont(ofSize: 12)
        signatureLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(signatureLabel)
        
        NSLayoutConstraint.activate([
            signatureLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: currentY),
            signatureLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        ])
    }
}

class ClassicTemplatePDFRenderer {
    let userProfile: UserProfile
    let template: CVTemplate
    let settings: CVSettings
    
    // Constants for classic template design
    private let pageSize = PDFGenerationService.dinA4Size
    private let margin: CGFloat = 35
    private let lineSpacing: CGFloat = 4
    private let sectionSpacing: CGFloat = 18
    
    // Modern Colors
    private let primaryColor = UIColor(hex: "#1a365d")  // Deep blue
    private let accentColor = UIColor(hex: "#3182ce")   // Bright blue
    private let secondaryColor = UIColor(hex: "#4a5568") // Medium gray
    private let textColor = UIColor(hex: "#2d3748")     // Dark gray
    private let lightTextColor = UIColor(hex: "#718096") // Light gray
    
    // Modern Typography
    private let nameFont = UIFont.boldSystemFont(ofSize: 28)
    private let titleFont = UIFont.systemFont(ofSize: 16, weight: .medium)
    private let sectionHeaderFont = UIFont.boldSystemFont(ofSize: 14)
    private let contentFont = UIFont.systemFont(ofSize: 11)
    private let detailFont = UIFont.systemFont(ofSize: 10)
    private let contactFont = UIFont.systemFont(ofSize: 12)
    
    init(userProfile: UserProfile, template: CVTemplate, settings: CVSettings) {
        self.userProfile = userProfile
        self.template = template
        self.settings = settings
    }
    
    func generatePDF() throws -> PDFDocument {
        let pageRect = CGRect(origin: .zero, size: pageSize)
        let contentRect = CGRect(x: margin, y: margin, width: pageSize.width - (2 * margin), height: pageSize.height - (2 * margin))
        let maxContentY = pageSize.height - margin - 50 // Leave space at bottom
        
        // Create PDF data
        let pdfData = NSMutableData()
        
        // Create PDF graphics context
        UIGraphicsBeginPDFContextToData(pdfData, pageRect, nil)
        UIGraphicsBeginPDFPage()
        
        var currentY = margin
        var isFirstPage = true
        
        // Draw header on first page
        currentY = drawHeader(at: CGPoint(x: margin, y: currentY), maxWidth: contentRect.width)
        currentY += sectionSpacing * 1.5
        
        // Draw sections in order
        for section in settings.sectionOrder {
            if settings.includedSections.contains(section) {
                // Calculate estimated section height
                let estimatedSectionHeight = estimateSectionHeight(section)
                
                // Check if section fits on current page
                if currentY + estimatedSectionHeight > maxContentY && !isFirstPage {
                    // Start new page
                    UIGraphicsBeginPDFPage()
                    currentY = margin
                    isFirstPage = false
                }
                
                // Draw section with potential page breaks
                currentY = drawSectionWithPageBreaks(section, startY: currentY, maxWidth: contentRect.width, maxContentY: maxContentY)
                currentY += sectionSpacing
                
                isFirstPage = false
            }
        }
        
        UIGraphicsEndPDFContext()
        
        // Create PDFDocument from the generated data
        guard let pdfDocument = PDFDocument(data: pdfData as Data) else {
            throw PDFGenerationError.renderingFailed("Failed to create PDF document from data")
        }
        
        return pdfDocument
    }
    
    private func estimateSectionHeight(_ section: CVSection) -> CGFloat {
        switch section {
        case .summary:
            return !userProfile.personalInfo.summary.isEmpty ? 60 : 0
        case .workExperience:
            return CGFloat(userProfile.workExperience.count * 70 + 30)
        case .education:
            return CGFloat(userProfile.education.count * 60 + 30)
        case .skills:
            return CGFloat(userProfile.skills.count * 50 + 30)
        case .projects:
            return CGFloat(userProfile.projects.count * 60 + 30)
        case .certificates:
            return CGFloat(userProfile.certificates.count * 40 + 30)
        case .languages:
            return CGFloat(userProfile.languages.count * 20 + 30)
        case .interests:
            return 50
        case .personalInfo:
            return 0 // Handled in header
        }
    }
    
    private func drawSectionWithPageBreaks(_ section: CVSection, startY: CGFloat, maxWidth: CGFloat, maxContentY: CGFloat) -> CGFloat {
        var currentY = startY
        
        // Skip sections with no data
        let hasData = sectionHasData(section)
        if !hasData {
            return currentY
        }
        
        // Check if section header fits
        if currentY + 30 > maxContentY {
            UIGraphicsBeginPDFPage()
            currentY = margin
        }
        
        // Draw section title
        let sectionTitle = section.localizedString.uppercased()
        let titleSize = drawText(sectionTitle, at: CGPoint(x: margin, y: currentY), font: sectionHeaderFont, color: primaryColor, maxWidth: maxWidth)
        currentY += titleSize.height + 6
        
        // Draw underline
        drawLine(from: CGPoint(x: margin, y: currentY), to: CGPoint(x: margin + titleSize.width + 20, y: currentY), color: accentColor, width: 2.0)
        currentY += 12
        
        // Draw section content with page breaks
        switch section {
        case .summary:
            currentY = drawSummarySectionWithPageBreaks(at: currentY, maxWidth: maxWidth, maxContentY: maxContentY)
        case .workExperience:
            currentY = drawWorkExperienceSectionWithPageBreaks(at: currentY, maxWidth: maxWidth, maxContentY: maxContentY)
        case .education:
            currentY = drawEducationSectionWithPageBreaks(at: currentY, maxWidth: maxWidth, maxContentY: maxContentY)
        case .skills:
            currentY = drawSkillsSectionWithPageBreaks(at: currentY, maxWidth: maxWidth, maxContentY: maxContentY)
        case .projects:
            currentY = drawProjectsSectionWithPageBreaks(at: currentY, maxWidth: maxWidth, maxContentY: maxContentY)
        case .certificates:
            currentY = drawCertificatesSectionWithPageBreaks(at: currentY, maxWidth: maxWidth, maxContentY: maxContentY)
        case .languages:
            currentY = drawLanguagesSectionWithPageBreaks(at: currentY, maxWidth: maxWidth, maxContentY: maxContentY)
        default:
            break
        }
        
        return currentY
    }
    
    private func drawSummarySectionWithPageBreaks(at startY: CGFloat, maxWidth: CGFloat, maxContentY: CGFloat) -> CGFloat {
        var currentY = startY
        
        if !userProfile.personalInfo.summary.isEmpty {
            let summaryHeight = estimateTextHeight(userProfile.personalInfo.summary, font: contentFont, maxWidth: maxWidth)
            
            // Check if summary fits on current page
            if currentY + summaryHeight > maxContentY {
                UIGraphicsBeginPDFPage()
                currentY = margin
            }
            
            let summarySize = drawText(userProfile.personalInfo.summary, at: CGPoint(x: margin, y: currentY), font: contentFont, color: textColor, maxWidth: maxWidth, numberOfLines: 0)
            currentY += summarySize.height + 12
        }
        
        return currentY
    }
    
    private func drawWorkExperienceSectionWithPageBreaks(at startY: CGFloat, maxWidth: CGFloat, maxContentY: CGFloat) -> CGFloat {
        var currentY = startY
        
        for experience in userProfile.workExperience {
            let entryHeight: CGFloat = 70 // Reduced height estimate
            
            // Check if entry fits on current page
            if currentY + entryHeight > maxContentY {
                UIGraphicsBeginPDFPage()
                currentY = margin
            }
            
            currentY += drawWorkExperienceEntry(experience, at: CGPoint(x: margin, y: currentY), maxWidth: maxWidth)
            currentY += lineSpacing * 2
        }
        
        return currentY
    }
    
    private func drawEducationSectionWithPageBreaks(at startY: CGFloat, maxWidth: CGFloat, maxContentY: CGFloat) -> CGFloat {
        var currentY = startY
        
        for education in userProfile.education {
            let entryHeight: CGFloat = 60 // Reduced height estimate
            
            // Check if entry fits on current page
            if currentY + entryHeight > maxContentY {
                UIGraphicsBeginPDFPage()
                currentY = margin
            }
            
            currentY += drawEducationEntry(education, at: CGPoint(x: margin, y: currentY), maxWidth: maxWidth)
            currentY += lineSpacing * 2
        }
        
        return currentY
    }
    
    private func drawSkillsSectionWithPageBreaks(at startY: CGFloat, maxWidth: CGFloat, maxContentY: CGFloat) -> CGFloat {
        var currentY = startY
        
        for skillCategory in userProfile.skills {
            let categoryHeight: CGFloat = 80 // Estimated height for skill category
            
            // Check if category fits on current page
            if currentY + categoryHeight > maxContentY {
                UIGraphicsBeginPDFPage()
                currentY = margin
            }
            
            // Category header
            let categoryFont = UIFont.boldSystemFont(ofSize: 12)
            let categorySize = drawText("\(skillCategory.categoryName)", at: CGPoint(x: margin, y: currentY), font: categoryFont, color: primaryColor, maxWidth: maxWidth)
            currentY += categorySize.height + 4
            
            // Skills as tags/pills
            var xOffset: CGFloat = margin + 16
            let skillsPerRow = 3
            var skillCount = 0
            
            for skill in skillCategory.skills {
                let skillText = skill.name
                let skillFont = UIFont.systemFont(ofSize: 10)
                
                // Calculate skill tag size
                let skillSize = skillText.size(withAttributes: [.font: skillFont])
                let tagWidth = skillSize.width + 16
                let tagHeight: CGFloat = 20
                
                // Check if we need to wrap to next line
                if xOffset + tagWidth > margin + maxWidth {
                    xOffset = margin + 16
                    currentY += tagHeight + 4
                }
                
                // Check if we need a new page
                if currentY + tagHeight > maxContentY {
                    UIGraphicsBeginPDFPage()
                    currentY = margin
                    xOffset = margin + 16
                }
                
                // Draw skill tag background
                let tagRect = CGRect(x: xOffset - 8, y: currentY - 2, width: tagWidth, height: tagHeight)
                UIColor(hex: "#e2e8f0").setFill()
                UIBezierPath(roundedRect: tagRect, cornerRadius: 10).fill()
                
                // Draw skill text
                drawText(skillText, at: CGPoint(x: xOffset, y: currentY + 2), font: skillFont, color: textColor, maxWidth: tagWidth - 16)
                
                xOffset += tagWidth + 8
                skillCount += 1
                
                if skillCount >= skillsPerRow {
                    xOffset = margin + 16
                    currentY += tagHeight + 4
                    skillCount = 0
                }
            }
            
            currentY += 16 // Spacing between skill categories
        }
        
        return currentY
    }
    
    private func drawProjectsSectionWithPageBreaks(at startY: CGFloat, maxWidth: CGFloat, maxContentY: CGFloat) -> CGFloat {
        var currentY = startY
        
        for project in userProfile.projects {
            let entryHeight: CGFloat = 60 // Reduced height estimate
            
            // Check if entry fits on current page
            if currentY + entryHeight > maxContentY {
                UIGraphicsBeginPDFPage()
                currentY = margin
            }
            
            currentY += drawProjectEntry(project, at: CGPoint(x: margin, y: currentY), maxWidth: maxWidth)
            currentY += lineSpacing * 2
        }
        
        return currentY
    }
    
    private func drawCertificatesSectionWithPageBreaks(at startY: CGFloat, maxWidth: CGFloat, maxContentY: CGFloat) -> CGFloat {
        var currentY = startY
        
        for certificate in userProfile.certificates {
            let entryHeight: CGFloat = 60 // Estimated height for certificate entry
            
            // Check if entry fits on current page
            if currentY + entryHeight > maxContentY {
                UIGraphicsBeginPDFPage()
                currentY = margin
            }
            
            currentY += drawCertificateEntry(certificate, at: CGPoint(x: margin, y: currentY), maxWidth: maxWidth)
            currentY += lineSpacing
        }
        
        return currentY
    }
    
    private func drawLanguagesSectionWithPageBreaks(at startY: CGFloat, maxWidth: CGFloat, maxContentY: CGFloat) -> CGFloat {
        var currentY = startY
        
        for language in userProfile.languages {
            let entryHeight: CGFloat = 30 // Estimated height for language entry
            
            // Check if entry fits on current page
            if currentY + entryHeight > maxContentY {
                UIGraphicsBeginPDFPage()
                currentY = margin
            }
            
            let languageText = "\(language.name): \(language.proficiencyLevel.localizedString)"
            let languageSize = drawText(languageText, at: CGPoint(x: margin, y: currentY), font: contentFont, color: textColor, maxWidth: maxWidth)
            currentY += languageSize.height + lineSpacing
        }
        
        return currentY
    }
    
    private func estimateTextHeight(_ text: String, font: UIFont, maxWidth: CGFloat) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let constraintSize = CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude)
        let boundingRect = attributedString.boundingRect(with: constraintSize, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        return boundingRect.height
    }
    
    
    private func drawHeader(at point: CGPoint, maxWidth: CGFloat) -> CGFloat {
        var currentY = point.y
        let startY = currentY
        
        // Header height with better spacing
        let headerHeight: CGFloat = 160
        
        // Draw professional light blue header background
        let headerRect = CGRect(x: 0, y: 0, width: pageSize.width, height: headerHeight)
        UIColor(hex: "#4a90c2").setFill()  // Professional medium blue
        UIBezierPath(rect: headerRect).fill()
        
        // Add a subtle gradient effect with a slightly darker blue at the bottom
        let gradientRect = CGRect(x: 0, y: headerHeight - 20, width: pageSize.width, height: 20)
        UIColor(hex: "#3d7ba8").setFill()
        UIBezierPath(rect: gradientRect).fill()
        
        currentY += 20  // Comfortable padding from top
        
        // Draw name with modern styling (white text on blue background)
        let fullName = "\(userProfile.personalInfo.firstName) \(userProfile.personalInfo.lastName)"
        let nameSize = drawText(fullName, at: CGPoint(x: point.x, y: currentY), font: nameFont, color: UIColor.white, maxWidth: maxWidth)
        currentY += nameSize.height + 12  // Better spacing after name
        
        // Draw title with lighter color
        if !userProfile.personalInfo.title.isEmpty {
            let titleSize = drawText(userProfile.personalInfo.title, at: CGPoint(x: point.x, y: currentY), font: titleFont, color: UIColor(hex: "#e8f4f8"), maxWidth: maxWidth)
            currentY += titleSize.height + 16  // Better spacing after title
        }
        
        // Draw contact information in a clean, modern way (light blue text)
        var contactInfo: [String] = []
        
        if !userProfile.personalInfo.email.isEmpty {
            contactInfo.append(userProfile.personalInfo.email)
        }
        if !userProfile.personalInfo.phone.isEmpty {
            contactInfo.append(userProfile.personalInfo.phone)
        }
        
        // Add address if available
        let address = userProfile.personalInfo.address
        if !address.city.isEmpty && !address.country.isEmpty {
            contactInfo.append("\(address.city), \(address.country)")
        }
        
        if !contactInfo.isEmpty {
            let contactText = contactInfo.joined(separator: " • ")
            let contactSize = drawText(contactText, at: CGPoint(x: point.x, y: currentY), font: contactFont, color: UIColor(hex: "#d4e9f7"), maxWidth: maxWidth)
            currentY += contactSize.height + 15  // Good spacing after contact
        }
        
        // Return to white background area
        currentY = headerHeight + 20  // Better spacing after header
        
        return currentY - startY
    }
    
    private func drawSection(_ section: CVSection, at point: CGPoint, maxWidth: CGFloat) -> CGFloat {
        var currentY = point.y
        let startY = currentY
        
        // Skip sections with no data
        let hasData = sectionHasData(section)
        if !hasData {
            return 0
        }
        
        // Draw section title with modern styling
        let sectionTitle = section.localizedString.uppercased()
        let titleSize = drawText(sectionTitle, at: CGPoint(x: point.x, y: currentY), font: sectionHeaderFont, color: primaryColor, maxWidth: maxWidth)
        currentY += titleSize.height + 6
        
        // Draw subtle underline for section
        drawLine(from: CGPoint(x: point.x, y: currentY), to: CGPoint(x: point.x + titleSize.width + 20, y: currentY), color: accentColor, width: 2.0)
        currentY += 15
        
        // Draw section content based on type
        switch section {
        case .summary:
            let contentHeight = drawSummarySection(at: CGPoint(x: point.x, y: currentY), maxWidth: maxWidth)
            currentY += contentHeight
        case .workExperience:
            let contentHeight = drawWorkExperienceSection(at: CGPoint(x: point.x, y: currentY), maxWidth: maxWidth)
            currentY += contentHeight
        case .education:
            let contentHeight = drawEducationSection(at: CGPoint(x: point.x, y: currentY), maxWidth: maxWidth)
            currentY += contentHeight
        case .skills:
            let contentHeight = drawSkillsSection(at: CGPoint(x: point.x, y: currentY), maxWidth: maxWidth)
            currentY += contentHeight
        case .projects:
            let contentHeight = drawProjectsSection(at: CGPoint(x: point.x, y: currentY), maxWidth: maxWidth)
            currentY += contentHeight
        case .certificates:
            let contentHeight = drawCertificatesSection(at: CGPoint(x: point.x, y: currentY), maxWidth: maxWidth)
            currentY += contentHeight
        case .languages:
            let contentHeight = drawLanguagesSection(at: CGPoint(x: point.x, y: currentY), maxWidth: maxWidth)
            currentY += contentHeight
        case .personalInfo, .interests:
            // These are handled in header or skipped
            break
        }
        
        return currentY - startY
    }
    
    private func drawSummarySection(at point: CGPoint, maxWidth: CGFloat) -> CGFloat {
        var currentY = point.y
        let startY = currentY
        
        // Draw summary text with proper formatting
        if !userProfile.personalInfo.summary.isEmpty {
            let summarySize = drawText(userProfile.personalInfo.summary, at: CGPoint(x: point.x, y: currentY), font: contentFont, color: textColor, maxWidth: maxWidth, numberOfLines: 0)
            currentY += summarySize.height + 15
        }
        
        return currentY - startY
    }
    
    private func sectionHasData(_ section: CVSection) -> Bool {
        switch section {
        case .workExperience:
            return !userProfile.workExperience.isEmpty
        case .education:
            return !userProfile.education.isEmpty
        case .skills:
            return !userProfile.skills.isEmpty
        case .projects:
            return !userProfile.projects.isEmpty
        case .certificates:
            return !userProfile.certificates.isEmpty
        case .languages:
            return !userProfile.languages.isEmpty
        case .interests:
            return !userProfile.interests.isEmpty
        case .summary:
            return !userProfile.personalInfo.summary.isEmpty
        case .personalInfo:
            return false // Never show - handled in header
        }
    }
    
    private func drawWorkExperienceSection(at point: CGPoint, maxWidth: CGFloat) -> CGFloat {
        var currentY = point.y
        let startY = currentY
        
        for experience in userProfile.workExperience {
            currentY += drawWorkExperienceEntry(experience, at: CGPoint(x: point.x, y: currentY), maxWidth: maxWidth)
            currentY += lineSpacing
        }
        
        return currentY - startY
    }
    
    private func drawWorkExperienceEntry(_ experience: WorkExperienceEntry, at point: CGPoint, maxWidth: CGFloat) -> CGFloat {
        var currentY = point.y
        let startY = currentY
        
        // Position title with modern styling
        let positionFont = UIFont.boldSystemFont(ofSize: 13)
        let positionSize = drawText(experience.position, at: CGPoint(x: point.x, y: currentY), font: positionFont, color: primaryColor, maxWidth: maxWidth * 0.65)
        
        // Date on the right with modern formatting
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM yyyy"
        let endDateText = experience.isCurrentJob ? "Present" : dateFormatter.string(from: experience.endDate ?? Date())
        let dateText = "\(dateFormatter.string(from: experience.startDate)) - \(endDateText)"
        let dateSize = drawText(dateText, at: CGPoint(x: point.x + maxWidth * 0.65, y: currentY), font: UIFont.systemFont(ofSize: 10, weight: .medium), color: accentColor, maxWidth: maxWidth * 0.35, alignment: .right)
        
        currentY += max(positionSize.height, dateSize.height) + 3
        
        // Company name
        let companySize = drawText(experience.company, at: CGPoint(x: point.x, y: currentY), font: UIFont.systemFont(ofSize: 11, weight: .medium), color: secondaryColor, maxWidth: maxWidth)
        currentY += companySize.height + 6
        
        // Description
        if !experience.description.isEmpty {
            let descriptionSize = drawText(experience.description, at: CGPoint(x: point.x, y: currentY), font: contentFont, color: textColor, maxWidth: maxWidth, numberOfLines: 3)
            currentY += descriptionSize.height + 8
        }
        
        // Achievements if any
        if !experience.achievements.isEmpty {
            for achievement in experience.achievements.prefix(2) { // Limit to 2 achievements
                let achievementText = "• \(achievement)"
                let achievementSize = drawText(achievementText, at: CGPoint(x: point.x + 8, y: currentY), font: UIFont.systemFont(ofSize: 10), color: secondaryColor, maxWidth: maxWidth - 8, numberOfLines: 1)
                currentY += achievementSize.height + 3
            }
        }
        
        return currentY - startY + 8 // Spacing between entries
    }
    
    private func drawEducationSection(at point: CGPoint, maxWidth: CGFloat) -> CGFloat {
        var currentY = point.y
        let startY = currentY
        
        for education in userProfile.education {
            currentY += drawEducationEntry(education, at: CGPoint(x: point.x, y: currentY), maxWidth: maxWidth)
            currentY += lineSpacing * 2
        }
        
        return currentY - startY
    }
    
    private func drawEducationEntry(_ education: EducationEntry, at point: CGPoint, maxWidth: CGFloat) -> CGFloat {
        var currentY = point.y
        let startY = currentY
        
        // Degree and field with modern styling
        let degreeText = "\(education.degree) in \(education.fieldOfStudy)"
        let degreeFont = UIFont.boldSystemFont(ofSize: 13)
        let degreeSize = drawText(degreeText, at: CGPoint(x: point.x, y: currentY), font: degreeFont, color: primaryColor, maxWidth: maxWidth * 0.65)
        
        // Date on the right with modern formatting
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM yyyy"
        let endDateText = education.isCurrentlyStudying ? "Present" : dateFormatter.string(from: education.endDate ?? Date())
        let dateText = "\(dateFormatter.string(from: education.startDate)) - \(endDateText)"
        let dateSize = drawText(dateText, at: CGPoint(x: point.x + maxWidth * 0.65, y: currentY), font: UIFont.systemFont(ofSize: 10, weight: .medium), color: accentColor, maxWidth: maxWidth * 0.35, alignment: .right)
        
        currentY += max(degreeSize.height, dateSize.height) + 3
        
        // Institution
        let institutionSize = drawText(education.institution, at: CGPoint(x: point.x, y: currentY), font: UIFont.systemFont(ofSize: 11, weight: .medium), color: secondaryColor, maxWidth: maxWidth)
        currentY += institutionSize.height + 6
        
        // Grade if available
        if !education.grade.isEmpty {
            let gradeText = "Grade: \(education.grade)"
            let gradeSize = drawText(gradeText, at: CGPoint(x: point.x, y: currentY), font: UIFont.systemFont(ofSize: 10), color: UIColor(hex: "#38a169"), maxWidth: maxWidth)
            currentY += gradeSize.height + 3
        }
        
        return currentY - startY + 8 // Spacing between entries
    }
    
    private func drawSkillsSection(at point: CGPoint, maxWidth: CGFloat) -> CGFloat {
        var currentY = point.y
        let startY = currentY
        
        for skillCategory in userProfile.skills {
            // Category header with modern styling
            let categoryFont = UIFont.boldSystemFont(ofSize: 12)
            let categorySize = drawText("\(skillCategory.categoryName)", at: CGPoint(x: point.x, y: currentY), font: categoryFont, color: primaryColor, maxWidth: maxWidth)
            currentY += categorySize.height + 4
            
            // Skills as modern tags/pills
            var xOffset: CGFloat = point.x + 16
            let skillsPerRow = 3
            var skillCount = 0
            
            for skill in skillCategory.skills {
                let skillText = skill.name
                let skillFont = UIFont.systemFont(ofSize: 10)
                
                // Calculate skill tag size
                let skillSize = skillText.size(withAttributes: [.font: skillFont])
                let tagWidth = skillSize.width + 16
                let tagHeight: CGFloat = 20
                
                // Check if we need to wrap to next line
                if xOffset + tagWidth > point.x + maxWidth {
                    xOffset = point.x + 16
                    currentY += tagHeight + 4
                }
                
                // Draw skill tag background
                let tagRect = CGRect(x: xOffset - 8, y: currentY - 2, width: tagWidth, height: tagHeight)
                UIColor(hex: "#e2e8f0").setFill()
                UIBezierPath(roundedRect: tagRect, cornerRadius: 10).fill()
                
                // Draw skill text
                drawText(skillText, at: CGPoint(x: xOffset, y: currentY + 2), font: skillFont, color: textColor, maxWidth: tagWidth - 16)
                
                xOffset += tagWidth + 8
                skillCount += 1
                
                if skillCount >= skillsPerRow {
                    xOffset = point.x + 16
                    currentY += tagHeight + 4
                    skillCount = 0
                }
            }
            
            currentY += 16 // Spacing between skill categories
        }
        
        return currentY - startY
    }
    
    private func drawProjectsSection(at point: CGPoint, maxWidth: CGFloat) -> CGFloat {
        var currentY = point.y
        let startY = currentY
        
        for project in userProfile.projects {
            currentY += drawProjectEntry(project, at: CGPoint(x: point.x, y: currentY), maxWidth: maxWidth)
            currentY += lineSpacing * 2
        }
        
        return currentY - startY
    }
    
    private func drawProjectEntry(_ project: Project, at point: CGPoint, maxWidth: CGFloat) -> CGFloat {
        var currentY = point.y
        let startY = currentY
        
        // Project name
        let nameFont = UIFont.boldSystemFont(ofSize: 12)
        let nameSize = drawText(project.name, at: CGPoint(x: point.x, y: currentY), font: nameFont, color: textColor, maxWidth: maxWidth)
        currentY += nameSize.height + lineSpacing
        
        // Description
        if !project.description.isEmpty {
            let descriptionSize = drawText(project.description, at: CGPoint(x: point.x, y: currentY), font: contentFont, color: textColor, maxWidth: maxWidth, numberOfLines: 2)
            currentY += descriptionSize.height + lineSpacing
        }
        
        // Technologies
        if !project.technologies.isEmpty {
            let techText = "Technologies: \(project.technologies.joined(separator: ", "))"
            let techSize = drawText(techText, at: CGPoint(x: point.x, y: currentY), font: detailFont, color: secondaryColor, maxWidth: maxWidth)
            currentY += techSize.height + lineSpacing
        }
        
        return currentY - startY
    }
    
    private func drawCertificatesSection(at point: CGPoint, maxWidth: CGFloat) -> CGFloat {
        var currentY = point.y
        let startY = currentY
        
        for certificate in userProfile.certificates {
            currentY += drawCertificateEntry(certificate, at: CGPoint(x: point.x, y: currentY), maxWidth: maxWidth)
            currentY += lineSpacing
        }
        
        return currentY - startY
    }
    
    private func drawCertificateEntry(_ certificate: Certificate, at point: CGPoint, maxWidth: CGFloat) -> CGFloat {
        var currentY = point.y
        let startY = currentY
        
        // Certificate name
        let nameFont = UIFont.boldSystemFont(ofSize: 11)
        let nameSize = drawText(certificate.name, at: CGPoint(x: point.x, y: currentY), font: nameFont, color: textColor, maxWidth: maxWidth * 0.7)
        
        // Date on the right
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let dateText = dateFormatter.string(from: certificate.issueDate)
        let dateSize = drawText(dateText, at: CGPoint(x: point.x + maxWidth * 0.7, y: currentY), font: detailFont, color: secondaryColor, maxWidth: maxWidth * 0.3, alignment: .right)
        
        currentY += max(nameSize.height, dateSize.height) + lineSpacing
        
        // Issuing organization
        let orgSize = drawText(certificate.issuingOrganization, at: CGPoint(x: point.x, y: currentY), font: detailFont, color: secondaryColor, maxWidth: maxWidth)
        currentY += orgSize.height + lineSpacing
        
        return currentY - startY
    }
    
    private func drawLanguagesSection(at point: CGPoint, maxWidth: CGFloat) -> CGFloat {
        var currentY = point.y
        let startY = currentY
        
        for language in userProfile.languages {
            let languageText = "\(language.name): \(language.proficiencyLevel.localizedString)"
            let languageSize = drawText(languageText, at: CGPoint(x: point.x, y: currentY), font: contentFont, color: textColor, maxWidth: maxWidth)
            currentY += languageSize.height + lineSpacing
        }
        
        return currentY - startY
    }
    
    // Helper drawing methods
    @discardableResult
    private func drawText(_ text: String, at point: CGPoint, font: UIFont, color: UIColor, maxWidth: CGFloat, numberOfLines: Int = 0, alignment: NSTextAlignment = .left) -> CGSize {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let constraintSize = CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude)
        let boundingRect = attributedString.boundingRect(with: constraintSize, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        
        var drawingRect = CGRect(origin: point, size: boundingRect.size)
        
        // Handle text alignment
        if alignment == .right {
            drawingRect.origin.x = point.x + maxWidth - boundingRect.width
        } else if alignment == .center {
            drawingRect.origin.x = point.x + (maxWidth - boundingRect.width) / 2
        }
        
        // Limit height if numberOfLines is specified
        if numberOfLines > 0 {
            let lineHeight = font.lineHeight
            let maxHeight = lineHeight * CGFloat(numberOfLines)
            if drawingRect.height > maxHeight {
                drawingRect.size.height = maxHeight
            }
        }
        
        attributedString.draw(in: drawingRect)
        
        return drawingRect.size
    }
    
    private func drawLine(from startPoint: CGPoint, to endPoint: CGPoint, color: UIColor, width: CGFloat = 1.0) {
        color.setStroke()
        
        let linePath = UIBezierPath()
        linePath.move(to: startPoint)
        linePath.addLine(to: endPoint)
        linePath.lineWidth = width
        linePath.stroke()
    }
}

class ModernTemplatePDFRenderer {
    let userProfile: UserProfile
    let template: CVTemplate
    let settings: CVSettings
    
    // Constants for modern template design exactly matching the image
    private let pageSize = PDFGenerationService.dinA4Size
    private let sidebarWidth: CGFloat = 280
    private let contentPadding: CGFloat = 20
    private let sectionSpacing: CGFloat = 15
    
    // Colors matching the image exactly
    private let sidebarColor = UIColor(hex: "#3B3B3B")
    private let textColor = UIColor.black
    private let whiteColor = UIColor.white
    
    // Modern Typography System - Using contemporary fonts for professional CV design
    private lazy var nameFont = ModernTemplatePDFRenderer.createModernFont(size: 32, weight: .bold)
    private lazy var titleFont = ModernTemplatePDFRenderer.createModernFont(size: 16, weight: .medium)
    private lazy var sectionHeaderFont = ModernTemplatePDFRenderer.createModernFont(size: 18, weight: .semibold)
    private lazy var sectionHeaderFontWhite = ModernTemplatePDFRenderer.createModernFont(size: 18, weight: .semibold)
    private lazy var contentFont = ModernTemplatePDFRenderer.createModernFont(size: 11, weight: .regular)
    private lazy var contentFontWhite = ModernTemplatePDFRenderer.createModernFont(size: 11, weight: .regular)
    private lazy var smallFont = ModernTemplatePDFRenderer.createModernFont(size: 10, weight: .regular)
    private lazy var dateFont = ModernTemplatePDFRenderer.createModernFont(size: 14, weight: .medium)
    private lazy var institutionFont = ModernTemplatePDFRenderer.createModernFont(size: 14, weight: .semibold)
    private lazy var degreeFont = ModernTemplatePDFRenderer.createModernFont(size: 12, weight: .regular)
    private lazy var positionFont = ModernTemplatePDFRenderer.createModernFont(size: 14, weight: .semibold)
    private lazy var companyFont = ModernTemplatePDFRenderer.createModernFont(size: 12, weight: .regular)
    private lazy var achievementFont = ModernTemplatePDFRenderer.createModernFont(size: 11, weight: .regular)
    
    // Modern font creation with fallbacks for maximum compatibility
    private static func createModernFont(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        // Try modern fonts in order of preference
        let modernFontNames = [
            "AvenirNext", // Contemporary, highly readable
            "Helvetica Neue", // Clean and modern
            "Avenir", // Excellent readability
            "SF Pro Display", // Apple's modern system font
            "SF Pro Text" // Apple's text optimized font
        ]
        
        // Map weight to font name suffix for custom fonts
        let weightSuffix: String
        switch weight {
        case .ultraLight: weightSuffix = "-UltraLight"
        case .thin: weightSuffix = "-Thin"
        case .light: weightSuffix = "-Light"
        case .regular: weightSuffix = "-Regular"
        case .medium: weightSuffix = "-Medium"
        case .semibold: weightSuffix = "-DemiBold"
        case .bold: weightSuffix = "-Bold"
        case .heavy: weightSuffix = "-Heavy"
        case .black: weightSuffix = "-Black"
        default: weightSuffix = "-Regular"
        }
        
        // Try each modern font
        for fontName in modernFontNames {
            let fullFontName = fontName + weightSuffix
            if let font = UIFont(name: fullFontName, size: size) {
                return font
            }
            // Try without weight suffix (for system fonts)
            if let font = UIFont(name: fontName, size: size) {
                return font
            }
        }
        
        // Fallback to system font with weight if no custom fonts are available
        return UIFont.systemFont(ofSize: size, weight: weight)
    }
    
    init(userProfile: UserProfile, template: CVTemplate, settings: CVSettings) {
        self.userProfile = userProfile
        self.template = template
        self.settings = settings
    }
    
    func generatePDF() throws -> PDFDocument {
        let pageRect = CGRect(origin: .zero, size: pageSize)
        
        // Create PDF data
        let pdfData = NSMutableData()
        
        // Create PDF graphics context
        UIGraphicsBeginPDFContextToData(pdfData, pageRect, nil)
        UIGraphicsBeginPDFPage()
        
        // Draw the template
        drawModernTemplate()
        
        UIGraphicsEndPDFContext()
        
        // Create PDFDocument from the generated data
        guard let pdfDocument = PDFDocument(data: pdfData as Data) else {
            throw PDFGenerationError.renderingFailed("Failed to create PDF document from data")
        }
        
        return pdfDocument
    }
    
    private func drawModernTemplate() {
        // Draw left sidebar with dark background (only on first page)
        drawSidebar()
        
        // Draw right content area with page break support
        drawContentAreaWithPageBreaks()
    }
    
    private func drawSidebar() {
        // Draw sidebar background
        let sidebarRect = CGRect(x: 0, y: 0, width: sidebarWidth, height: pageSize.height)
        sidebarColor.setFill()
        UIBezierPath(rect: sidebarRect).fill()
        
        var currentY: CGFloat = contentPadding
        
        // Draw profile picture
        currentY = drawProfilePicture(at: CGPoint(x: contentPadding, y: currentY))
        currentY += 25
        
        // Draw About Me section
        currentY = drawAboutMeSection(at: CGPoint(x: contentPadding, y: currentY))
        currentY += sectionSpacing
        
        // Draw Contact section
        currentY = drawContactSection(at: CGPoint(x: contentPadding, y: currentY))
        currentY += sectionSpacing
        
        // Draw Skills section
        currentY = drawSkillsSection(at: CGPoint(x: contentPadding, y: currentY))
        currentY += sectionSpacing
        
        // Draw Language section
        currentY = drawLanguageSection(at: CGPoint(x: contentPadding, y: currentY))
    }
    
    private func drawContentArea() {
        let contentX = sidebarWidth + contentPadding
        let contentWidth = pageSize.width - sidebarWidth - (contentPadding * 2)
        var currentY: CGFloat = 40
        
        // Draw header (name and title)
        currentY = drawHeader(at: CGPoint(x: contentX, y: currentY), maxWidth: contentWidth)
        currentY += 40
        
        // Draw Education section
        currentY = drawEducationSection(at: CGPoint(x: contentX, y: currentY), maxWidth: contentWidth)
        currentY += 40
        
        // Draw Experience section
        currentY = drawExperienceSection(at: CGPoint(x: contentX, y: currentY), maxWidth: contentWidth)
    }
    
    private func drawContentAreaWithPageBreaks() {
        let contentX = sidebarWidth + contentPadding
        let contentWidth = pageSize.width - sidebarWidth - (contentPadding * 2)
        let maxContentY = pageSize.height - contentPadding - 50
        var currentY: CGFloat = 40
        var isFirstPage = true
        
        // Draw header (name and title) on first page
        currentY = drawHeader(at: CGPoint(x: contentX, y: currentY), maxWidth: contentWidth)
        currentY += 25
        
        // Draw Education section
        let educationEntries = getEducationEntries()
        if !educationEntries.isEmpty {
            // Check if education section header fits
            if currentY + 50 > maxContentY {
                startNewPage()
                currentY = 40
                isFirstPage = false
            }
            
            // Draw section header
            let headerText = "Education"
            currentY += drawSectionHeader(headerText, at: CGPoint(x: contentX, y: currentY), isWhiteText: false)
            currentY += 12
            
            // Draw entries with page break support
            for (index, entry) in educationEntries.enumerated() {
                let entryHeight: CGFloat = 80 // Estimated height for education entry
                
                // Check if entry fits on current page
                if currentY + entryHeight > maxContentY {
                    startNewPage()
                    currentY = 40
                    isFirstPage = false
                }
                
                currentY += drawEducationEntry(entry, at: CGPoint(x: contentX, y: currentY), maxWidth: contentWidth, isLast: index == educationEntries.count - 1)
                currentY += 15
            }
            
            currentY += 20
        }
        
        // Draw Experience section
        let experienceEntries = getExperienceEntries()
        if !experienceEntries.isEmpty {
            // Check if experience section header fits
            if currentY + 50 > maxContentY {
                startNewPage()
                currentY = 40
                isFirstPage = false
            }
            
            // Draw section header
            let headerText = "Experience"
            currentY += drawSectionHeader(headerText, at: CGPoint(x: contentX, y: currentY), isWhiteText: false)
            currentY += 12
            
            // Draw entries with page break support
            for (index, entry) in experienceEntries.enumerated() {
                let entryHeight: CGFloat = 100 // Estimated height for experience entry
                
                // Check if entry fits on current page
                if currentY + entryHeight > maxContentY {
                    startNewPage()
                    currentY = 40
                    isFirstPage = false
                }
                
                currentY += drawExperienceEntry(entry, at: CGPoint(x: contentX, y: currentY), maxWidth: contentWidth, isLast: index == experienceEntries.count - 1)
                currentY += 15
            }
        }
    }
    
    private func startNewPage() {
        UIGraphicsBeginPDFPage()
        // Don't draw sidebar on subsequent pages for modern template
        // Only draw content area background if needed
    }
    
    
    private func drawAboutMeSection(at point: CGPoint) -> CGFloat {
        var currentY = point.y
        
        // Section header
        let headerText = "About Me"
        currentY += drawSectionHeader(headerText, at: CGPoint(x: point.x, y: currentY), isWhiteText: true)
        currentY += 12
        
        // About text
        let aboutText = userProfile.personalInfo.summary.isEmpty ? 
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam pharetra in lorem at laoreet. Donec hendrerit libero eget est tempor, quis tempus arcu elementum." : 
            userProfile.personalInfo.summary
        
        let maxWidth = sidebarWidth - (contentPadding * 2)
        currentY += drawMultilineText(aboutText, at: CGPoint(x: point.x, y: currentY), font: contentFontWhite, color: whiteColor, maxWidth: maxWidth, lineSpacing: 2)
        
        return currentY
    }
    
    private func drawContactSection(at point: CGPoint) -> CGFloat {
        var currentY = point.y
        
        // Section header
        let headerText = "Contact"
        currentY += drawSectionHeader(headerText, at: CGPoint(x: point.x, y: currentY), isWhiteText: true)
        currentY += 20
        
        // Contact entries
        let phone = userProfile.personalInfo.phone.isEmpty ? "+123-456-7890" : userProfile.personalInfo.phone
        let email = userProfile.personalInfo.email.isEmpty ? "hello@reallygreatsite.com" : userProfile.personalInfo.email
        let address = formatAddress()
        
        currentY += drawContactRow(phone, at: CGPoint(x: point.x, y: currentY))
        currentY += 12
        currentY += drawContactRow(email, at: CGPoint(x: point.x, y: currentY))
        currentY += 12
        currentY += drawContactRow(address, at: CGPoint(x: point.x, y: currentY))
        
        return currentY
    }
    
    private func drawSkillsSection(at point: CGPoint) -> CGFloat {
        var currentY = point.y
        
        // Section header
        let headerText = "Skills"
        currentY += drawSectionHeader(headerText, at: CGPoint(x: point.x, y: currentY), isWhiteText: true)
        currentY += 20
        
        // Skills list
        let skills = getSkillsList()
        for skill in skills {
            currentY += drawBulletPoint(skill, at: CGPoint(x: point.x, y: currentY))
            currentY += 8
        }
        
        return currentY
    }
    
    private func drawLanguageSection(at point: CGPoint) -> CGFloat {
        var currentY = point.y
        
        // Section header
        let headerText = "Language"
        currentY += drawSectionHeader(headerText, at: CGPoint(x: point.x, y: currentY), isWhiteText: true)
        currentY += 20
        
        // Languages list
        let languages = getLanguagesList()
        for language in languages {
            currentY += drawBulletPoint(language, at: CGPoint(x: point.x, y: currentY))
            currentY += 8
        }
        
        return currentY
    }
    
    private func drawProfilePicture(at point: CGPoint) -> CGFloat {
        let imageSize: CGFloat = 140
        let imageCenter = CGPoint(x: point.x + (sidebarWidth - contentPadding * 2) / 2, y: point.y + imageSize / 2)
        
        if let profileImageData = userProfile.personalInfo.profileImageData,
           let image = UIImage(data: profileImageData) {
            // Draw the actual profile image with proper aspect ratio handling
            let imageRect = CGRect(x: imageCenter.x - imageSize/2, y: imageCenter.y - imageSize/2, width: imageSize, height: imageSize)
            
            // Save the current graphics state
            guard let context = UIGraphicsGetCurrentContext() else { return imageSize + 10 }
            context.saveGState()
            
            // Create circular clipping path
            let circlePath = UIBezierPath(ovalIn: imageRect)
            circlePath.addClip()
            
            // Calculate aspect ratio and draw image to fill circle while maintaining proportions
            let imageAspectRatio = image.size.width / image.size.height
            let circleAspectRatio: CGFloat = 1.0 // Circle is always 1:1
            
            var drawRect: CGRect
            if imageAspectRatio > circleAspectRatio {
                // Image is wider than circle - fit height and center horizontally
                let drawHeight = imageSize
                let drawWidth = drawHeight * imageAspectRatio
                let offsetX = (imageSize - drawWidth) / 2
                drawRect = CGRect(x: imageRect.minX + offsetX, y: imageRect.minY, width: drawWidth, height: drawHeight)
            } else {
                // Image is taller than circle - fit width and center vertically
                let drawWidth = imageSize
                let drawHeight = drawWidth / imageAspectRatio
                let offsetY = (imageSize - drawHeight) / 2
                drawRect = CGRect(x: imageRect.minX, y: imageRect.minY + offsetY, width: drawWidth, height: drawHeight)
            }
            
            // Draw image with proper aspect ratio
            image.draw(in: drawRect)
            
            // Restore graphics state (removes clipping)
            context.restoreGState()
            
            // Draw white border
            whiteColor.setStroke()
            let whiteBorderPath = UIBezierPath(ovalIn: imageRect)
            whiteBorderPath.lineWidth = 6
            whiteBorderPath.stroke()
            
            // Draw black outer border
            textColor.setStroke()
            let blackBorderPath = UIBezierPath(ovalIn: imageRect.insetBy(dx: -3, dy: -3))
            blackBorderPath.lineWidth = 3
            blackBorderPath.stroke()
        } else {
            // Draw placeholder circle
            let imageRect = CGRect(x: imageCenter.x - imageSize/2, y: imageCenter.y - imageSize/2, width: imageSize, height: imageSize)
            
            // Fill with light gray background
            UIColor.gray.withAlphaComponent(0.3).setFill()
            UIBezierPath(ovalIn: imageRect).fill()
            
            // Draw person icon (simplified)
            UIColor.gray.setFill()
            let iconRect = CGRect(x: imageCenter.x - 30, y: imageCenter.y - 20, width: 60, height: 40)
            UIBezierPath(ovalIn: iconRect).fill()
            
            // Draw borders matching the style
            whiteColor.setStroke()
            let whiteBorderPath = UIBezierPath(ovalIn: imageRect)
            whiteBorderPath.lineWidth = 6
            whiteBorderPath.stroke()
            
            textColor.setStroke()
            let blackBorderPath = UIBezierPath(ovalIn: imageRect.insetBy(dx: -3, dy: -3))
            blackBorderPath.lineWidth = 3
            blackBorderPath.stroke()
        }
        
        return imageSize + 10
    }
    
    private func drawHeader(at point: CGPoint, maxWidth: CGFloat) -> CGFloat {
        var currentY = point.y
        
        // Name (right-aligned with proper text fitting)
        let fullName = userProfile.personalInfo.firstName.isEmpty && userProfile.personalInfo.lastName.isEmpty ? 
            "Isabel Schumacher" : "\(userProfile.personalInfo.firstName) \(userProfile.personalInfo.lastName)"
        
        // Draw name with proper text fitting
        currentY += drawRightAlignedText(fullName, at: CGPoint(x: point.x, y: currentY), font: nameFont, color: textColor, maxWidth: maxWidth)
        currentY += 8
        
        // Title (right-aligned with proper text fitting)
        let jobTitle = userProfile.personalInfo.title.isEmpty ? "Graphics Designer" : userProfile.personalInfo.title
        
        // Draw title with proper text fitting
        currentY += drawRightAlignedText(jobTitle, at: CGPoint(x: point.x, y: currentY), font: titleFont, color: textColor, maxWidth: maxWidth)
        
        return currentY
    }
    
    @discardableResult
    private func drawRightAlignedText(_ text: String, at point: CGPoint, font: UIFont, color: UIColor, maxWidth: CGFloat) -> CGFloat {
        // Calculate text size
        let textSize = text.size(withAttributes: [.font: font])
        
        // If text fits, draw it right-aligned
        if textSize.width <= maxWidth {
            let x = point.x + maxWidth - textSize.width
            drawText(text, at: CGPoint(x: x, y: point.y), font: font, color: color)
            return textSize.height
        }
        
        // If text is too long, truncate and fit it to the available width
        let availableRect = CGRect(x: point.x, y: point.y, width: maxWidth, height: textSize.height)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .right
        paragraphStyle.lineBreakMode = .byTruncatingTail
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        attributedString.draw(in: availableRect)
        
        return textSize.height
    }
    
    private func drawEducationSection(at point: CGPoint, maxWidth: CGFloat) -> CGFloat {
        var currentY = point.y
        
        // Section header
        let headerText = "Education"
        currentY += drawSectionHeader(headerText, at: CGPoint(x: point.x, y: currentY), isWhiteText: false)
        currentY += 20
        
        // Education entries
        let educationEntries = getEducationEntries()
        for (index, entry) in educationEntries.enumerated() {
            currentY += drawEducationEntry(entry, at: CGPoint(x: point.x, y: currentY), maxWidth: maxWidth, isLast: index == educationEntries.count - 1)
            currentY += 25
        }
        
        return currentY
    }
    
    private func drawExperienceSection(at point: CGPoint, maxWidth: CGFloat) -> CGFloat {
        var currentY = point.y
        
        // Section header
        let headerText = "Experience"
        currentY += drawSectionHeader(headerText, at: CGPoint(x: point.x, y: currentY), isWhiteText: false)
        currentY += 20
        
        // Experience entries
        let experienceEntries = getExperienceEntries()
        for (index, entry) in experienceEntries.enumerated() {
            currentY += drawExperienceEntry(entry, at: CGPoint(x: point.x, y: currentY), maxWidth: maxWidth, isLast: index == experienceEntries.count - 1)
            currentY += 25
        }
        
        return currentY
    }
    
    // Helper methods
    private func drawSectionHeader(_ text: String, at point: CGPoint, isWhiteText: Bool) -> CGFloat {
        let font = isWhiteText ? sectionHeaderFontWhite : sectionHeaderFont
        let color = isWhiteText ? whiteColor : textColor
        
        drawText(text, at: point, font: font, color: color)
        return font.lineHeight
    }
    
    private func drawContactRow(_ text: String, at point: CGPoint) -> CGFloat {
        // Draw bullet point
        whiteColor.setFill()
        let bulletRect = CGRect(x: point.x, y: point.y + 5, width: 4, height: 4)
        UIBezierPath(ovalIn: bulletRect).fill()
        
        // Draw text
        drawText(text, at: CGPoint(x: point.x + 10, y: point.y), font: contentFontWhite, color: whiteColor)
        return contentFontWhite.lineHeight
    }
    
    private func drawBulletPoint(_ text: String, at point: CGPoint) -> CGFloat {
        // Draw bullet point
        whiteColor.setFill()
        let bulletRect = CGRect(x: point.x, y: point.y + 5, width: 4, height: 4)
        UIBezierPath(ovalIn: bulletRect).fill()
        
        // Draw text
        drawText(text, at: CGPoint(x: point.x + 10, y: point.y), font: contentFontWhite, color: whiteColor)
        return contentFontWhite.lineHeight
    }
    
    private func drawEducationEntry(_ entry: EducationDisplayEntry, at point: CGPoint, maxWidth: CGFloat, isLast: Bool) -> CGFloat {
        var currentY = point.y
        
        // Draw timeline dot
        textColor.setFill()
        let dotRect = CGRect(x: point.x, y: currentY + 2, width: 8, height: 8)
        UIBezierPath(ovalIn: dotRect).fill()
        
        // Draw timeline line (if not last)
        if !isLast {
            textColor.setStroke()
            let linePath = UIBezierPath()
            linePath.move(to: CGPoint(x: point.x + 4, y: currentY + 10))
            linePath.addLine(to: CGPoint(x: point.x + 4, y: currentY + 50))
            linePath.lineWidth = 2
            linePath.stroke()
        }
        
        // Draw content
        let contentX = point.x + 15
        let contentWidth = maxWidth - 15
        
        // Date
        drawText(entry.dateRange, at: CGPoint(x: contentX, y: currentY), font: dateFont, color: textColor)
        currentY += 18
        
        // Institution
        drawText(entry.institution, at: CGPoint(x: contentX, y: currentY), font: institutionFont, color: textColor)
        currentY += 16
        
        // Degree
        drawText(entry.degree, at: CGPoint(x: contentX, y: currentY), font: degreeFont, color: textColor)
        currentY += 14
        
        // Grade
        if !entry.grade.isEmpty {
            drawText(entry.grade, at: CGPoint(x: contentX, y: currentY), font: degreeFont, color: textColor)
            currentY += 14
        }
        
        return currentY - point.y
    }
    
    private func drawExperienceEntry(_ entry: ExperienceDisplayEntry, at point: CGPoint, maxWidth: CGFloat, isLast: Bool) -> CGFloat {
        var currentY = point.y
        
        // Draw timeline dot
        textColor.setFill()
        let dotRect = CGRect(x: point.x, y: currentY + 2, width: 8, height: 8)
        UIBezierPath(ovalIn: dotRect).fill()
        
        // Draw timeline line (if not last)
        if !isLast {
            textColor.setStroke()
            let linePath = UIBezierPath()
            linePath.move(to: CGPoint(x: point.x + 4, y: currentY + 10))
            linePath.addLine(to: CGPoint(x: point.x + 4, y: currentY + 70))
            linePath.lineWidth = 2
            linePath.stroke()
        }
        
        // Draw content
        let contentX = point.x + 15
        let contentWidth = maxWidth - 15
        
        // Date
        drawText(entry.dateRange, at: CGPoint(x: contentX, y: currentY), font: dateFont, color: textColor)
        currentY += 18
        
        // Position
        drawText(entry.position, at: CGPoint(x: contentX, y: currentY), font: positionFont, color: textColor)
        currentY += 16
        
        // Company
        drawText(entry.company, at: CGPoint(x: contentX, y: currentY), font: companyFont, color: textColor)
        currentY += 16
        
        // Achievements
        for achievement in entry.achievements.prefix(2) {
            // Draw bullet
            textColor.setFill()
            let bulletRect = CGRect(x: contentX, y: currentY + 4, width: 3, height: 3)
            UIBezierPath(ovalIn: bulletRect).fill()
            
            // Draw achievement text
            currentY += drawMultilineText(achievement, at: CGPoint(x: contentX + 8, y: currentY), font: achievementFont, color: textColor, maxWidth: contentWidth - 8, lineSpacing: 1)
            currentY += 4
        }
        
        return currentY - point.y
    }
    
    @discardableResult
    private func drawText(_ text: String, at point: CGPoint, font: UIFont, color: UIColor) -> CGSize {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let size = attributedString.size()
        
        attributedString.draw(at: point)
        
        return size
    }
    
    @discardableResult
    private func drawMultilineText(_ text: String, at point: CGPoint, font: UIFont, color: UIColor, maxWidth: CGFloat, lineSpacing: CGFloat) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let constraintSize = CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude)
        let boundingRect = attributedString.boundingRect(with: constraintSize, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        
        let drawingRect = CGRect(origin: point, size: boundingRect.size)
        attributedString.draw(in: drawingRect)
        
        return boundingRect.height
    }
    
    // Data helper methods (same as before)
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
    
    private func getExperienceEntries() -> [ExperienceDisplayEntry] {
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

struct EducationDisplayEntry: Identifiable {
    let id: UUID
    let dateRange: String
    let institution: String
    let degree: String
    let grade: String
}

struct ExperienceDisplayEntry: Identifiable {
    let id: UUID
    let dateRange: String
    let position: String
    let company: String
    let achievements: [String]
}

class CreativeTemplatePDFRenderer {
    let userProfile: UserProfile
    let template: CVTemplate
    let settings: CVSettings
    
    // Constants for creative template design
    private let pageSize = PDFGenerationService.dinA4Size
    private let margin: CGFloat = 25
    private let contentSpacing: CGFloat = 20
    
    // Creative color scheme
    private let headerColor = UIColor(hex: "#4A4A4A")  // Dark gray header
    private let accentColor = UIColor(hex: "#D4AF37")  // Gold accent
    private let summaryBackgroundColor = UIColor(hex: "#D2B48C")  // Tan/beige
    private let textColor = UIColor.black
    private let lightTextColor = UIColor(hex: "#666666")
    private let timelineColor = UIColor(hex: "#D4AF37")  // Gold timeline
    
    // Typography
    private let nameFont = UIFont.boldSystemFont(ofSize: 32)
    private let titleFont = UIFont.systemFont(ofSize: 18, weight: .medium)
    private let sectionHeaderFont = UIFont.boldSystemFont(ofSize: 16)
    private let contentFont = UIFont.systemFont(ofSize: 11)
    private let detailFont = UIFont.systemFont(ofSize: 10)
    private let contactFont = UIFont.systemFont(ofSize: 12)
    
    init(userProfile: UserProfile, template: CVTemplate, settings: CVSettings) {
        self.userProfile = userProfile
        self.template = template
        self.settings = settings
    }
    
    func generatePDF() throws -> PDFDocument {
        let pageRect = CGRect(origin: .zero, size: pageSize)
        
        // Create PDF data
        let pdfData = NSMutableData()
        
        // Create PDF graphics context
        UIGraphicsBeginPDFContextToData(pdfData, pageRect, nil)
        UIGraphicsBeginPDFPage()
        
        // Draw the creative template
        drawCreativeTemplate()
        
        UIGraphicsEndPDFContext()
        
        // Create PDFDocument from the generated data
        guard let pdfDocument = PDFDocument(data: pdfData as Data) else {
            throw PDFGenerationError.renderingFailed("Failed to create PDF document from data")
        }
        
        return pdfDocument
    }
    
    private func drawCreativeTemplate() {
        var currentY: CGFloat = 0
        
        // Draw header section
        currentY = drawHeader()
        
        // Draw profile section with image and summary
        currentY = drawProfileSection(startY: currentY)
        
        // Draw main content sections
        drawMainContent(startY: currentY)
    }
    
    private func drawHeader() -> CGFloat {
        let headerHeight: CGFloat = 120
        
        // Draw dark header background
        let headerRect = CGRect(x: 0, y: 0, width: pageSize.width, height: headerHeight)
        headerColor.setFill()
        UIBezierPath(rect: headerRect).fill()
        
        // Draw name (left side)
        let fullName = "\(userProfile.personalInfo.firstName) \(userProfile.personalInfo.lastName)"
        drawText(fullName, at: CGPoint(x: margin, y: 20), font: nameFont, color: .white)
        
        // Draw title below name
        let jobTitle = userProfile.personalInfo.title.isEmpty ? "Sales Manager" : userProfile.personalInfo.title
        drawText(jobTitle, at: CGPoint(x: margin, y: 60), font: titleFont, color: UIColor(hex: "#CCCCCC"))
        
        // Draw contact info (right side) - exactly like in image
        let rightMargin = margin
        var contactY: CGFloat = 15
        
        // Location (top right, gold color)
        let address = userProfile.personalInfo.address
        let location = address.city.isEmpty ? "Pittsburgh, Pennsylvania" : "\(address.city), \(address.country)"
        drawRightAlignedText(location, at: CGPoint(x: pageSize.width - rightMargin, y: contactY), font: contactFont, color: accentColor)
        contactY += 18
        
        // Phone and divider and email (one line)
        let phone = userProfile.personalInfo.phone.isEmpty ? "+012 3456 7890" : userProfile.personalInfo.phone
        let email = userProfile.personalInfo.email.isEmpty ? "rajan@email.com" : userProfile.personalInfo.email
        let contactLine = "\(phone)    |    \(email)"
        drawRightAlignedText(contactLine, at: CGPoint(x: pageSize.width - rightMargin, y: contactY), font: UIFont.systemFont(ofSize: 11), color: .white)
        contactY += 18
        
        // LinkedIn (bottom right, gold color)
        let linkedinUrl = "linkedin.com/in/rajanhines"
        drawRightAlignedText(linkedinUrl, at: CGPoint(x: pageSize.width - rightMargin, y: contactY), font: UIFont.systemFont(ofSize: 11), color: accentColor)
        
        return headerHeight
    }
    
    private func drawProfileSection(startY: CGFloat) -> CGFloat {
        let sectionHeight: CGFloat = 180
        var currentY = startY
        
        // Draw profile image (left side, circular)
        let imageSize: CGFloat = 140
        let imageX = margin + 20
        let imageY = currentY + 20
        
        drawProfileImage(at: CGPoint(x: imageX, y: imageY), size: imageSize)
        
        // Draw summary background (right side)
        let summaryX = imageX + imageSize + 30
        let summaryWidth = pageSize.width - summaryX - margin
        let summaryRect = CGRect(x: summaryX, y: currentY + 10, width: summaryWidth, height: sectionHeight - 20)
        
        // Draw rounded background for summary
        summaryBackgroundColor.setFill()
        UIBezierPath(roundedRect: summaryRect, cornerRadius: 15).fill()
        
        // Draw summary text
        let summaryText = userProfile.personalInfo.summary.isEmpty ? 
            "Sales manager with five years of experience and a focus on goal setting and accountability. Seeking an opportunity to work for a renowned sales corporation where my management style of fostering employee excellence can develop intentional, self-driven employees." : 
            userProfile.personalInfo.summary
        
        let summaryTextRect = summaryRect.insetBy(dx: 25, dy: 25)
        drawMultilineText(summaryText, in: summaryTextRect, font: UIFont.systemFont(ofSize: 12), color: .white)
        
        return currentY + sectionHeight
    }
    
    private func drawMainContent(startY: CGFloat) {
        let leftColumnX = margin
        let leftColumnWidth: CGFloat = 200
        let rightColumnX = leftColumnX + leftColumnWidth + 40
        let rightColumnWidth = pageSize.width - rightColumnX - margin
        
        var leftY = startY + 30
        var rightY = startY + 30
        
        // Left column: Education, Skills, Languages
        leftY = drawEducationSection(at: CGPoint(x: leftColumnX, y: leftY), maxWidth: leftColumnWidth)
        leftY += contentSpacing
        
        leftY = drawSkillsSection(at: CGPoint(x: leftColumnX, y: leftY), maxWidth: leftColumnWidth)
        leftY += contentSpacing
        
        leftY = drawLanguagesSection(at: CGPoint(x: leftColumnX, y: leftY), maxWidth: leftColumnWidth)
        
        // Right column: Working Experience with timeline
        rightY = drawWorkingExperienceSection(at: CGPoint(x: rightColumnX, y: rightY), maxWidth: rightColumnWidth)
    }
    
    private func drawEducationSection(at point: CGPoint, maxWidth: CGFloat) -> CGFloat {
        var currentY = point.y
        
        // Section header
        currentY += drawSectionHeader("Education", at: CGPoint(x: point.x, y: currentY))
        currentY += 15
        
        // Education entries
        for education in userProfile.education {
            // Degree
            let degreeText = "\(education.degree) and\n\(education.fieldOfStudy)"
            currentY += drawMultilineText(degreeText, at: CGPoint(x: point.x, y: currentY), font: UIFont.boldSystemFont(ofSize: 12), color: textColor, maxWidth: maxWidth)
            currentY += 8
            
            // Institution
            currentY += drawText(education.institution, at: CGPoint(x: point.x, y: currentY), font: contentFont, color: lightTextColor)
            currentY += 5
            
            // Dates
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy"
            let startYear = dateFormatter.string(from: education.startDate)
            let endYear = education.endDate != nil ? dateFormatter.string(from: education.endDate!) : "Present"
            let dateText = "\(startYear) - \(endYear)"
            currentY += drawText(dateText, at: CGPoint(x: point.x, y: currentY), font: detailFont, color: lightTextColor)
            currentY += 20
        }
        
        return currentY
    }
    
    private func drawSkillsSection(at point: CGPoint, maxWidth: CGFloat) -> CGFloat {
        var currentY = point.y
        
        // Section header
        currentY += drawSectionHeader("Skills", at: CGPoint(x: point.x, y: currentY))
        currentY += 15
        
        // Skills with checkboxes
        let allSkills = userProfile.skills.flatMap { category in
            category.skills.map { $0.name }
        }
        
        let skillsToShow = allSkills.isEmpty ? 
            ["Outbound sales", "CRM", "Detail oriented", "People management"] : 
            Array(allSkills.prefix(4))
        
        for skill in skillsToShow {
            // Draw checkbox
            let checkboxRect = CGRect(x: point.x, y: currentY, width: 12, height: 12)
            lightTextColor.setStroke()
            UIBezierPath(rect: checkboxRect).stroke()
            
            // Draw checkmark
            accentColor.setStroke()
            let checkPath = UIBezierPath()
            checkPath.move(to: CGPoint(x: checkboxRect.minX + 2, y: checkboxRect.midY))
            checkPath.addLine(to: CGPoint(x: checkboxRect.midX, y: checkboxRect.maxY - 2))
            checkPath.addLine(to: CGPoint(x: checkboxRect.maxX - 2, y: checkboxRect.minY + 2))
            checkPath.lineWidth = 2
            checkPath.stroke()
            
            // Draw skill text
            drawText(skill, at: CGPoint(x: point.x + 20, y: currentY - 2), font: contentFont, color: textColor)
            currentY += 20
        }
        
        return currentY
    }
    
    private func drawLanguagesSection(at point: CGPoint, maxWidth: CGFloat) -> CGFloat {
        var currentY = point.y
        
        // Section header
        currentY += drawSectionHeader("Languages", at: CGPoint(x: point.x, y: currentY))
        currentY += 20
        
        // Language entries with progress bars
        let languagesToShow = userProfile.languages.isEmpty ? 
            [("English", "Excellent"), ("Spanish", "Intermediate"), ("French", "Intermediate")] :
            userProfile.languages.map { ($0.name, $0.proficiencyLevel.localizedString) }
        
        for (language, level) in languagesToShow {
            // Language name
            drawText("\(language) - \(level)", at: CGPoint(x: point.x, y: currentY), font: contentFont, color: textColor)
            currentY += 15
            
            // Progress bar
            let barWidth = maxWidth - 20
            let barHeight: CGFloat = 4
            let progress: CGFloat = level.lowercased().contains("excellent") ? 1.0 : 
                                   level.lowercased().contains("intermediate") ? 0.7 : 0.5
            
            // Background bar
            let backgroundRect = CGRect(x: point.x, y: currentY, width: barWidth, height: barHeight)
            UIColor.lightGray.setFill()
            UIBezierPath(roundedRect: backgroundRect, cornerRadius: barHeight/2).fill()
            
            // Progress bar
            let progressRect = CGRect(x: point.x, y: currentY, width: barWidth * progress, height: barHeight)
            accentColor.setFill()
            UIBezierPath(roundedRect: progressRect, cornerRadius: barHeight/2).fill()
            
            currentY += 25
        }
        
        return currentY
    }
    
    private func drawWorkingExperienceSection(at point: CGPoint, maxWidth: CGFloat) -> CGFloat {
        var currentY = point.y
        
        // Section header with diamond
        drawDiamond(at: CGPoint(x: point.x - 20, y: currentY + 5), color: accentColor)
        currentY += drawSectionHeader("Working Experience", at: CGPoint(x: point.x, y: currentY))
        currentY += 20
        
        // Timeline line
        let timelineX = point.x - 20
        
        // Work experience entries
        for (index, experience) in userProfile.workExperience.enumerated() {
            let isLast = index == userProfile.workExperience.count - 1
            
            // Draw timeline elements
            drawTimelineEntry(at: CGPoint(x: timelineX, y: currentY), isLast: isLast)
            
            // Position and company
            let positionText = experience.position
            currentY += drawText(positionText, at: CGPoint(x: point.x, y: currentY), font: UIFont.boldSystemFont(ofSize: 12), color: textColor)
            currentY += 5
            
            let companyText = experience.company
            currentY += drawText(companyText, at: CGPoint(x: point.x, y: currentY), font: contentFont, color: lightTextColor)
            currentY += 8
            
            // Dates
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/yyyy"
            let startDate = dateFormatter.string(from: experience.startDate)
            let endDate = experience.isCurrentJob ? "Present" : dateFormatter.string(from: experience.endDate ?? Date())
            let dateText = "\(startDate) - \(endDate)"
            currentY += drawText(dateText, at: CGPoint(x: point.x, y: currentY), font: detailFont, color: lightTextColor)
            currentY += 12
            
            // Achievements
            let achievements = experience.achievements.isEmpty ? 
                [experience.description] : 
                Array(experience.achievements.prefix(3))
            
            for achievement in achievements {
                if !achievement.isEmpty {
                    // Bullet point
                    drawBulletPoint(at: CGPoint(x: point.x, y: currentY + 4))
                    currentY += drawMultilineText(achievement, at: CGPoint(x: point.x + 10, y: currentY), font: detailFont, color: textColor, maxWidth: maxWidth - 10)
                    currentY += 8
                }
            }
            
            currentY += 25
        }
        
        return currentY
    }
    
    // Helper drawing methods
    private func drawProfileImage(at point: CGPoint, size: CGFloat) {
        let imageRect = CGRect(x: point.x, y: point.y, width: size, height: size)
        
        if let profileImageData = userProfile.personalInfo.profileImageData,
           let image = UIImage(data: profileImageData) {
            // Save graphics state
            guard let context = UIGraphicsGetCurrentContext() else { return }
            context.saveGState()
            
            // Create circular clipping path
            let circlePath = UIBezierPath(ovalIn: imageRect)
            circlePath.addClip()
            
            // Calculate aspect ratio and draw image to fit circle while maintaining proportions
            let imageAspectRatio = image.size.width / image.size.height
            let circleAspectRatio: CGFloat = 1.0 // Circle is always 1:1
            
            var drawRect: CGRect
            if imageAspectRatio > circleAspectRatio {
                // Image is wider than circle - fit height and center horizontally
                let drawHeight = size
                let drawWidth = drawHeight * imageAspectRatio
                let offsetX = (size - drawWidth) / 2
                drawRect = CGRect(x: imageRect.minX + offsetX, y: imageRect.minY, width: drawWidth, height: drawHeight)
            } else {
                // Image is taller than circle - fit width and center vertically
                let drawWidth = size
                let drawHeight = drawWidth / imageAspectRatio
                let offsetY = (size - drawHeight) / 2
                drawRect = CGRect(x: imageRect.minX, y: imageRect.minY + offsetY, width: drawWidth, height: drawHeight)
            }
            
            // Draw image with proper aspect ratio
            image.draw(in: drawRect)
            
            // Restore graphics state
            context.restoreGState()
            
            // Draw golden border
            accentColor.setStroke()
            let borderPath = UIBezierPath(ovalIn: imageRect)
            borderPath.lineWidth = 4
            borderPath.stroke()
        } else {
            // Draw placeholder
            UIColor.lightGray.setFill()
            UIBezierPath(ovalIn: imageRect).fill()
            
            // Draw golden border
            accentColor.setStroke()
            let borderPath = UIBezierPath(ovalIn: imageRect)
            borderPath.lineWidth = 4
            borderPath.stroke()
        }
    }
    
    private func drawDiamond(at point: CGPoint, color: UIColor) {
        let size: CGFloat = 8
        color.setFill()
        
        let diamondPath = UIBezierPath()
        diamondPath.move(to: CGPoint(x: point.x, y: point.y - size/2))
        diamondPath.addLine(to: CGPoint(x: point.x + size/2, y: point.y))
        diamondPath.addLine(to: CGPoint(x: point.x, y: point.y + size/2))
        diamondPath.addLine(to: CGPoint(x: point.x - size/2, y: point.y))
        diamondPath.close()
        diamondPath.fill()
    }
    
    private func drawTimelineEntry(at point: CGPoint, isLast: Bool) {
        // Draw diamond
        drawDiamond(at: point, color: accentColor)
        
        // Draw line if not last
        if !isLast {
            timelineColor.setStroke()
            let linePath = UIBezierPath()
            linePath.move(to: CGPoint(x: point.x, y: point.y + 5))
            linePath.addLine(to: CGPoint(x: point.x, y: point.y + 80))
            linePath.lineWidth = 2
            linePath.stroke()
        }
    }
    
    private func drawBulletPoint(at point: CGPoint) {
        textColor.setFill()
        let bulletRect = CGRect(x: point.x, y: point.y, width: 3, height: 3)
        UIBezierPath(ovalIn: bulletRect).fill()
    }
    
    @discardableResult
    private func drawSectionHeader(_ text: String, at point: CGPoint) -> CGFloat {
        drawText(text, at: point, font: sectionHeaderFont, color: accentColor)
        return sectionHeaderFont.lineHeight
    }
    
    @discardableResult
    private func drawText(_ text: String, at point: CGPoint, font: UIFont, color: UIColor, alignment: NSTextAlignment = .left) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let size = attributedString.size()
        
        attributedString.draw(at: point)
        
        return size.height
    }
    
    @discardableResult
    private func drawRightAlignedText(_ text: String, at point: CGPoint, font: UIFont, color: UIColor) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let size = attributedString.size()
        
        // Adjust position to align right
        let adjustedPoint = CGPoint(x: point.x - size.width, y: point.y)
        attributedString.draw(at: adjustedPoint)
        
        return size.height
    }
    
    @discardableResult
    private func drawMultilineText(_ text: String, at point: CGPoint, font: UIFont, color: UIColor, maxWidth: CGFloat) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let constraintSize = CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude)
        let boundingRect = attributedString.boundingRect(with: constraintSize, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        
        let drawingRect = CGRect(origin: point, size: boundingRect.size)
        attributedString.draw(in: drawingRect)
        
        return boundingRect.height
    }
    
    private func drawMultilineText(_ text: String, in rect: CGRect, font: UIFont, color: UIColor) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        attributedString.draw(in: rect)
    }
}

class ProfessionalTemplatePDFRenderer {
    let userProfile: UserProfile
    let template: CVTemplate
    let settings: CVSettings
    
    // Constants for professional template design
    private let pageSize = PDFGenerationService.dinA4Size
    private let margin: CGFloat = 30
    private let columnSpacing: CGFloat = 25
    private let sectionSpacing: CGFloat = 15
    
    // Professional color scheme (matching the green/teal design)
    private let accentColor = UIColor(hex: "#7FB3D3")  // Light blue/teal
    private let darkAccentColor = UIColor(hex: "#5A8DB3")  // Darker blue/teal
    private let headerBackgroundColor = UIColor(hex: "#E8F4F8")  // Very light blue background
    private let sectionHeaderColor = UIColor(hex: "#2D4A56")  // Dark blue-gray
    private let textColor = UIColor.black
    private let lightTextColor = UIColor(hex: "#666666")
    
    // Typography
    private let nameFont = UIFont.boldSystemFont(ofSize: 28)
    private let titleFont = UIFont.systemFont(ofSize: 14)
    private let sectionHeaderFont = UIFont.boldSystemFont(ofSize: 12)
    private let contentFont = UIFont.systemFont(ofSize: 10)
    private let contactFont = UIFont.systemFont(ofSize: 9)
    
    init(userProfile: UserProfile, template: CVTemplate, settings: CVSettings) {
        self.userProfile = userProfile
        self.template = template
        self.settings = settings
    }
    
    func generatePDF() throws -> PDFDocument {
        let pageRect = CGRect(origin: .zero, size: pageSize)
        
        // Create PDF data
        let pdfData = NSMutableData()
        
        // Create PDF graphics context
        UIGraphicsBeginPDFContextToData(pdfData, pageRect, nil)
        UIGraphicsBeginPDFPage()
        
        // Draw the professional template
        drawProfessionalTemplate()
        
        UIGraphicsEndPDFContext()
        
        // Create PDFDocument from the generated data
        guard let pdfDocument = PDFDocument(data: pdfData as Data) else {
            throw PDFGenerationError.renderingFailed("Failed to create PDF document from data")
        }
        
        return pdfDocument
    }
    
    private func drawProfessionalTemplate() {
        var currentY: CGFloat = 0
        
        // Draw header section
        currentY = drawHeader()
        
        // Draw profile section
        currentY = drawProfileSection(startY: currentY)
        
        // Draw main content in two columns
        drawMainContent(startY: currentY)
    }
    
    private func drawHeader() -> CGFloat {
        let headerHeight: CGFloat = 120
        
        // Draw light background for header
        let headerRect = CGRect(x: 0, y: 0, width: pageSize.width, height: headerHeight)
        headerBackgroundColor.setFill()
        UIBezierPath(rect: headerRect).fill()
        
        // Contact info section (left side with icons)
        var contactY: CGFloat = 20
        let contactX: CGFloat = margin
        
        // Phone
        drawContactLine(icon: "📞", text: userProfile.personalInfo.phone.isEmpty ? "017657501141" : userProfile.personalInfo.phone, 
                      at: CGPoint(x: contactX, y: contactY))
        contactY += 18
        
        // Email
        drawContactLine(icon: "✉", text: userProfile.personalInfo.email.isEmpty ? "Bene-held@web.de" : userProfile.personalInfo.email, 
                      at: CGPoint(x: contactX, y: contactY))
        contactY += 18
        
        // Address
        let address = userProfile.personalInfo.address
        let addressText = address.street.isEmpty ? "123 Australia Canberra 123" : "\(address.street) \(address.city) \(address.postalCode)"
        drawContactLine(icon: "📍", text: addressText, at: CGPoint(x: contactX, y: contactY))
        
        // Name and title (centered and larger)
        let centerX = pageSize.width / 2
        let fullName = userProfile.personalInfo.firstName.isEmpty && userProfile.personalInfo.lastName.isEmpty ? 
            "BENEDIKT HELD" : "\(userProfile.personalInfo.firstName.uppercased()) \(userProfile.personalInfo.lastName.uppercased())"
        
        // Calculate name size for centering (single line)
        let nameAttributes: [NSAttributedString.Key: Any] = [
            .font: nameFont,
            .foregroundColor: textColor
        ]
        let nameString = NSAttributedString(string: fullName, attributes: nameAttributes)
        let nameSize = nameString.size()
        
        // Draw name centered (single line)
        let nameX = centerX - nameSize.width / 2
        drawText(fullName, at: CGPoint(x: nameX, y: 25), font: nameFont, color: textColor)
        
        // Draw title centered below name
        let jobTitle = userProfile.personalInfo.title.isEmpty ? "Software Developer" : userProfile.personalInfo.title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: lightTextColor
        ]
        let titleString = NSAttributedString(string: jobTitle, attributes: titleAttributes)
        let titleSize = titleString.size()
        let titleX = centerX - titleSize.width / 2
        
        drawText(jobTitle, at: CGPoint(x: titleX, y: 60), font: titleFont, color: lightTextColor)
        
        return headerHeight
    }
    
    private func drawProfileSection(startY: CGFloat) -> CGFloat {
        let sectionHeight: CGFloat = 120
        var currentY = startY + 15
        
        // Profile image (left side, circular)
        let imageSize: CGFloat = 80
        let imageX = margin + 10
        let imageY = currentY + 10
        
        drawProfileImage(at: CGPoint(x: imageX, y: imageY), size: imageSize)
        
        // Summary text (right side)
        let summaryX = imageX + imageSize + 20
        let summaryWidth = pageSize.width - summaryX - margin
        
        let summaryText = userProfile.personalInfo.summary.isEmpty ? 
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus scelerisque lorem vitae mi. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus scelerisque lorem vitae mi. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus scelerisque lorem vitae mi. Lorem ipsum dolor sit amet, consectetur adipiscing elit." : 
            userProfile.personalInfo.summary
        
        drawMultilineText(summaryText, at: CGPoint(x: summaryX, y: currentY + 20), font: contentFont, color: textColor, maxWidth: summaryWidth)
        
        return currentY + sectionHeight
    }
    
    private func drawMainContent(startY: CGFloat) {
        let leftColumnX = margin
        let leftColumnWidth: CGFloat = 160
        let rightColumnX = leftColumnX + leftColumnWidth + columnSpacing
        let rightColumnWidth = pageSize.width - rightColumnX - margin
        
        var leftY = startY + 20
        var rightY = startY + 20
        
        // Left column: Education, Skills, Interests
        leftY = drawEducationSection(at: CGPoint(x: leftColumnX, y: leftY), maxWidth: leftColumnWidth)
        leftY += sectionSpacing
        
        leftY = drawSkillsSection(at: CGPoint(x: leftColumnX, y: leftY), maxWidth: leftColumnWidth)
        leftY += sectionSpacing
        
        leftY = drawInterestsSection(at: CGPoint(x: leftColumnX, y: leftY), maxWidth: leftColumnWidth)
        
        // Right column: Experience, References
        rightY = drawExperienceSection(at: CGPoint(x: rightColumnX, y: rightY), maxWidth: rightColumnWidth)
        rightY += sectionSpacing
        
        rightY = drawReferencesSection(at: CGPoint(x: rightColumnX, y: rightY), maxWidth: rightColumnWidth)
    }
    
    private func drawEducationSection(at point: CGPoint, maxWidth: CGFloat) -> CGFloat {
        var currentY = point.y
        
        // Section header
        currentY += drawSectionHeader("EDUCATION", at: CGPoint(x: point.x, y: currentY), maxWidth: maxWidth)
        currentY += 12
        
        // Education entries
        let educationEntries = userProfile.education.isEmpty ? [
            ("Master in Computer Tecno", "Education", "University Name", "2016-2018"),
            ("Bachelor of Science", "Education", "University Name", "2014-2016")
        ] : userProfile.education.map { education in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy"
            let startYear = dateFormatter.string(from: education.startDate)
            let endYear = education.endDate != nil ? dateFormatter.string(from: education.endDate!) : "Present"
            return (education.degree, education.fieldOfStudy, education.institution, "\(startYear)-\(endYear)")
        }
        
        for (degree, field, institution, dates) in educationEntries {
            // Degree title
            currentY += drawText(degree, at: CGPoint(x: point.x, y: currentY), font: UIFont.boldSystemFont(ofSize: 11), color: textColor)
            currentY += 3
            
            // Field and institution
            currentY += drawText(field, at: CGPoint(x: point.x, y: currentY), font: contentFont, color: lightTextColor)
            currentY += 3
            currentY += drawText(institution, at: CGPoint(x: point.x, y: currentY), font: contentFont, color: lightTextColor)
            currentY += 3
            currentY += drawText(dates, at: CGPoint(x: point.x, y: currentY), font: contentFont, color: lightTextColor)
            currentY += 15
        }
        
        return currentY
    }
    
    private func drawSkillsSection(at point: CGPoint, maxWidth: CGFloat) -> CGFloat {
        var currentY = point.y
        
        // Section header
        currentY += drawSectionHeader("SKILLS", at: CGPoint(x: point.x, y: currentY), maxWidth: maxWidth)
        currentY += 12
        
        // Skills with progress bars
        let allSkills = userProfile.skills.flatMap { category in
            category.skills.map { ($0.name, $0.proficiencyLevel) }
        }
        
        let skillsToShow = allSkills.isEmpty ? [
            ("Photoshop", 0.9),
            ("Illustrator", 0.8),
            ("InDesign", 0.85),
            ("After Effect", 0.7)
        ] : Array(allSkills.prefix(4).map { 
            let level = proficiencyLevelToProgress($0.1)
            return ($0.0, level)
        })
        
        for (skillName, level) in skillsToShow {
            // Skill name
            currentY += drawText(skillName, at: CGPoint(x: point.x, y: currentY), font: contentFont, color: textColor)
            currentY += 8
            
            // Progress bar
            let barWidth = maxWidth - 10
            let barHeight: CGFloat = 3
            
            // Background bar
            let backgroundRect = CGRect(x: point.x, y: currentY, width: barWidth, height: barHeight)
            UIColor.lightGray.setFill()
            UIBezierPath(rect: backgroundRect).fill()
            
            // Progress bar
            let progressRect = CGRect(x: point.x, y: currentY, width: barWidth * CGFloat(level), height: barHeight)
            accentColor.setFill()
            UIBezierPath(rect: progressRect).fill()
            
            currentY += 15
        }
        
        return currentY
    }
    
    private func drawInterestsSection(at point: CGPoint, maxWidth: CGFloat) -> CGFloat {
        var currentY = point.y
        
        // Section header
        currentY += drawSectionHeader("INTERESTS", at: CGPoint(x: point.x, y: currentY), maxWidth: maxWidth)
        currentY += 12
        
        // Interests list
        let interests = userProfile.interests.isEmpty ? 
            ["Internet Dev", "Internet Tour", "Internet Travel"] : 
            Array(userProfile.interests.prefix(3))
        
        for interest in interests {
            currentY += drawText(interest, at: CGPoint(x: point.x, y: currentY), font: contentFont, color: textColor)
            currentY += 12
        }
        
        return currentY
    }
    
    private func drawExperienceSection(at point: CGPoint, maxWidth: CGFloat) -> CGFloat {
        var currentY = point.y
        
        // Section header
        currentY += drawSectionHeader("EXPERIENCE", at: CGPoint(x: point.x, y: currentY), maxWidth: maxWidth)
        currentY += 12
        
        // Experience entries
        let experienceEntries = userProfile.workExperience.isEmpty ? [
            ("POSITION TITLE HERE", "Company Location goes here", "2016-2017", [
                "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus scelerisque lorem vitae mi",
                "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus scelerisque lorem vitae mi"
            ])
        ] : Array(userProfile.workExperience.prefix(3).map { experience in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy"
            let startYear = dateFormatter.string(from: experience.startDate)
            let endYear = experience.isCurrentJob ? "Present" : dateFormatter.string(from: experience.endDate ?? Date())
            let achievements = experience.achievements.isEmpty ? [experience.description] : Array(experience.achievements.prefix(3))
            return (experience.position, experience.company, "\(startYear)-\(endYear)", achievements)
        })
        
        for (position, company, dates, achievements) in experienceEntries {
            // Position title
            currentY += drawText(position, at: CGPoint(x: point.x, y: currentY), font: UIFont.boldSystemFont(ofSize: 11), color: textColor)
            currentY += 3
            
            // Company and dates
            currentY += drawText(company, at: CGPoint(x: point.x, y: currentY), font: contentFont, color: lightTextColor)
            currentY += 3
            currentY += drawText(dates, at: CGPoint(x: point.x, y: currentY), font: contentFont, color: lightTextColor)
            currentY += 8
            
            // Achievements
            for achievement in achievements {
                if !achievement.isEmpty {
                    // Bullet point
                    drawBulletPoint(at: CGPoint(x: point.x, y: currentY + 3))
                    currentY += drawMultilineText(achievement, at: CGPoint(x: point.x + 8, y: currentY), font: contentFont, color: textColor, maxWidth: maxWidth - 8)
                    currentY += 5
                }
            }
            
            currentY += 15
        }
        
        return currentY
    }
    
    private func drawReferencesSection(at point: CGPoint, maxWidth: CGFloat) -> CGFloat {
        var currentY = point.y
        
        // Section header
        currentY += drawSectionHeader("REFERENCES", at: CGPoint(x: point.x, y: currentY), maxWidth: maxWidth)
        currentY += 12
        
        // References (mock data as this is typically confidential)
        let references = [
            ("MD. Jone Martin", "Graphic Designer & Developer", "T : +1234 5678 9101", "E : jdoemartin@mail.com"),
            ("MD. Alex Maxim", "Graphic Designer & Developer", "T : +1234 5678 9102", "E : alexmaxim@mail.com")
        ]
        
        for (name, title, phone, email) in references {
            currentY += drawText(name, at: CGPoint(x: point.x, y: currentY), font: UIFont.boldSystemFont(ofSize: 10), color: textColor)
            currentY += 3
            currentY += drawText(title, at: CGPoint(x: point.x, y: currentY), font: contentFont, color: lightTextColor)
            currentY += 3
            currentY += drawText(phone, at: CGPoint(x: point.x, y: currentY), font: contentFont, color: lightTextColor)
            currentY += 3
            currentY += drawText(email, at: CGPoint(x: point.x, y: currentY), font: contentFont, color: lightTextColor)
            currentY += 15
        }
        
        return currentY
    }
    
    // Helper methods
    private func proficiencyLevelToProgress(_ level: ProficiencyLevel) -> Double {
        switch level {
        case .beginner:
            return 0.3
        case .intermediate:
            return 0.6
        case .advanced:
            return 0.8
        case .expert:
            return 1.0
        }
    }
    
    // Helper drawing methods
    private func drawContactLine(icon: String, text: String, at point: CGPoint) {
        // Draw circle background
        let circleSize: CGFloat = 14
        let circleRect = CGRect(x: point.x, y: point.y - 2, width: circleSize, height: circleSize)
        accentColor.setFill()
        UIBezierPath(ovalIn: circleRect).fill()
        
        // Draw simple geometric icon in the circle
        let iconColor = UIColor.white
        iconColor.setStroke()
        iconColor.setFill()
        
        let centerX = circleRect.midX
        let centerY = circleRect.midY
        let iconSize: CGFloat = 6
        
        switch icon {
        case "📞": // Phone icon - simple curved line
            let phonePath = UIBezierPath()
            phonePath.move(to: CGPoint(x: centerX - 2, y: centerY - 2))
            phonePath.addCurve(to: CGPoint(x: centerX + 2, y: centerY + 2), 
                              controlPoint1: CGPoint(x: centerX - 1, y: centerY + 1), 
                              controlPoint2: CGPoint(x: centerX + 1, y: centerY - 1))
            phonePath.lineWidth = 1.5
            phonePath.stroke()
            
        case "✉": // Email icon - envelope shape
            let envelopeRect = CGRect(x: centerX - 3, y: centerY - 2, width: 6, height: 4)
            UIBezierPath(rect: envelopeRect).stroke()
            
            let trianglePath = UIBezierPath()
            trianglePath.move(to: CGPoint(x: envelopeRect.minX, y: envelopeRect.minY))
            trianglePath.addLine(to: CGPoint(x: centerX, y: centerY))
            trianglePath.addLine(to: CGPoint(x: envelopeRect.maxX, y: envelopeRect.minY))
            trianglePath.lineWidth = 1
            trianglePath.stroke()
            
        case "📍": // Location icon - pin shape
            let pinPath = UIBezierPath(ovalIn: CGRect(x: centerX - 2, y: centerY - 2, width: 4, height: 4))
            pinPath.fill()
            
            let pinTipPath = UIBezierPath()
            pinTipPath.move(to: CGPoint(x: centerX, y: centerY + 1))
            pinTipPath.addLine(to: CGPoint(x: centerX, y: centerY + 3))
            pinTipPath.lineWidth = 1
            pinTipPath.stroke()
            
        default:
            // Default dot
            UIBezierPath(ovalIn: CGRect(x: centerX - 1, y: centerY - 1, width: 2, height: 2)).fill()
        }
        
        // Draw contact text
        drawText(text, at: CGPoint(x: point.x + circleSize + 10, y: point.y - 2), font: contactFont, color: textColor)
    }
    
    private func drawProfileImage(at point: CGPoint, size: CGFloat) {
        let imageRect = CGRect(x: point.x, y: point.y, width: size, height: size)
        
        if let profileImageData = userProfile.personalInfo.profileImageData,
           let image = UIImage(data: profileImageData) {
            // Save graphics state
            guard let context = UIGraphicsGetCurrentContext() else { return }
            context.saveGState()
            
            // Create circular clipping path
            let circlePath = UIBezierPath(ovalIn: imageRect)
            circlePath.addClip()
            
            // Calculate aspect ratio and draw image properly
            let imageAspectRatio = image.size.width / image.size.height
            var drawRect: CGRect
            
            if imageAspectRatio > 1.0 {
                // Image is wider - fit height and center horizontally
                let drawHeight = size
                let drawWidth = drawHeight * imageAspectRatio
                let offsetX = (size - drawWidth) / 2
                drawRect = CGRect(x: imageRect.minX + offsetX, y: imageRect.minY, width: drawWidth, height: drawHeight)
            } else {
                // Image is taller - fit width and center vertically
                let drawWidth = size
                let drawHeight = drawWidth / imageAspectRatio
                let offsetY = (size - drawHeight) / 2
                drawRect = CGRect(x: imageRect.minX, y: imageRect.minY + offsetY, width: drawWidth, height: drawHeight)
            }
            
            // Draw image
            image.draw(in: drawRect)
            
            // Restore graphics state
            context.restoreGState()
        } else {
            // Draw placeholder
            UIColor.lightGray.setFill()
            UIBezierPath(ovalIn: imageRect).fill()
        }
        
        // Draw border
        accentColor.setStroke()
        let borderPath = UIBezierPath(ovalIn: imageRect)
        borderPath.lineWidth = 2
        borderPath.stroke()
    }
    
    private func drawBulletPoint(at point: CGPoint) {
        textColor.setFill()
        let bulletRect = CGRect(x: point.x, y: point.y, width: 2, height: 2)
        UIBezierPath(ovalIn: bulletRect).fill()
    }
    
    @discardableResult
    private func drawSectionHeader(_ text: String, at point: CGPoint, maxWidth: CGFloat) -> CGFloat {
        // Draw background
        let headerHeight: CGFloat = 18
        let headerRect = CGRect(x: point.x, y: point.y, width: maxWidth, height: headerHeight)
        sectionHeaderColor.setFill()
        UIBezierPath(rect: headerRect).fill()
        
        // Draw text
        drawText(text, at: CGPoint(x: point.x + 8, y: point.y + 4), font: sectionHeaderFont, color: .white)
        
        return headerHeight
    }
    
    @discardableResult
    private func drawText(_ text: String, at point: CGPoint, font: UIFont, color: UIColor) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let size = attributedString.size()
        
        attributedString.draw(at: point)
        
        return size.height
    }
    
    @discardableResult
    private func drawMultilineText(_ text: String, at point: CGPoint, font: UIFont, color: UIColor, maxWidth: CGFloat) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let constraintSize = CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude)
        let boundingRect = attributedString.boundingRect(with: constraintSize, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        
        let drawingRect = CGRect(origin: point, size: boundingRect.size)
        attributedString.draw(in: drawingRect)
        
        return boundingRect.height
    }
}

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            alpha: Double(a) / 255
        )
    }
}