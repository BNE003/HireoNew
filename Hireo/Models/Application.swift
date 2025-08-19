//
//  Application.swift
//  Hireo
//
//  Created by Benedikt Held on 19.08.25.
//

import Foundation

struct Application: Codable, Identifiable {
    let id = UUID()
    var companyName: String
    var position: String
    var applicationDate: Date
    var status: ApplicationStatus
    var notes: String
    var contactPerson: ContactPerson?
    var jobDescription: String
    var customCVSettings: CVSettings?
    var customCoverLetterContent: CoverLetterContent?
    var createdAt: Date
    var lastModified: Date
    
    init(companyName: String = "", position: String = "") {
        self.companyName = companyName
        self.position = position
        self.applicationDate = Date()
        self.status = .draft
        self.notes = ""
        self.contactPerson = nil
        self.jobDescription = ""
        self.customCVSettings = nil
        self.customCoverLetterContent = nil
        self.createdAt = Date()
        self.lastModified = Date()
    }
}

enum ApplicationStatus: String, CaseIterable, Codable {
    case draft = "Draft"
    case sent = "Sent"
    case interview = "Interview"
    case rejected = "Rejected"
    case accepted = "Accepted"
    case withdrawn = "Withdrawn"
    
    var localizedString: String {
        switch self {
        case .draft: return NSLocalizedString("application.status.draft", comment: "")
        case .sent: return NSLocalizedString("application.status.sent", comment: "")
        case .interview: return NSLocalizedString("application.status.interview", comment: "")
        case .rejected: return NSLocalizedString("application.status.rejected", comment: "")
        case .accepted: return NSLocalizedString("application.status.accepted", comment: "")
        case .withdrawn: return NSLocalizedString("application.status.withdrawn", comment: "")
        }
    }
    
    var color: String {
        switch self {
        case .draft: return "gray"
        case .sent: return "blue"
        case .interview: return "orange"
        case .rejected: return "red"
        case .accepted: return "green"
        case .withdrawn: return "purple"
        }
    }
}

struct ContactPerson: Codable {
    var name: String
    var position: String
    var email: String?
    var phone: String?
    
    init() {
        self.name = ""
        self.position = ""
        self.email = nil
        self.phone = nil
    }
}

struct CVSettings: Codable {
    var templateId: String
    var colorScheme: String
    var fontFamily: String
    var includedSections: [CVSection]
    var sectionOrder: [CVSection]
    
    init() {
        self.templateId = "modern"
        self.colorScheme = "blue"
        self.fontFamily = "system"
        self.includedSections = CVSection.allCases
        self.sectionOrder = CVSection.allCases
    }
}

enum CVSection: String, CaseIterable, Codable {
    case personalInfo = "PersonalInfo"
    case summary = "Summary"
    case workExperience = "WorkExperience"
    case education = "Education"
    case skills = "Skills"
    case projects = "Projects"
    case certificates = "Certificates"
    case languages = "Languages"
    case interests = "Interests"
    
    var localizedString: String {
        switch self {
        case .personalInfo: return NSLocalizedString("cv.section.personal_info", comment: "")
        case .summary: return NSLocalizedString("cv.section.summary", comment: "")
        case .workExperience: return NSLocalizedString("cv.section.work_experience", comment: "")
        case .education: return NSLocalizedString("cv.section.education", comment: "")
        case .skills: return NSLocalizedString("cv.section.skills", comment: "")
        case .projects: return NSLocalizedString("cv.section.projects", comment: "")
        case .certificates: return NSLocalizedString("cv.section.certificates", comment: "")
        case .languages: return NSLocalizedString("cv.section.languages", comment: "")
        case .interests: return NSLocalizedString("cv.section.interests", comment: "")
        }
    }
}

struct CoverLetterContent: Codable {
    var templateId: String
    var recipientCompany: String
    var recipientName: String?
    var recipientPosition: String?
    var salutation: String
    var introduction: String
    var body: String
    var closing: String
    var signature: String
    
    init() {
        self.templateId = "professional"
        self.recipientCompany = ""
        self.recipientName = nil
        self.recipientPosition = nil
        self.salutation = ""
        self.introduction = ""
        self.body = ""
        self.closing = ""
        self.signature = ""
    }
}