//
//  UserProfile.swift
//  Hireo
//
//  Created by Benedikt Held on 19.08.25.
//

import Foundation

struct UserProfile: Codable, Identifiable {
    let id = UUID()
    var personalInfo: PersonalInfo
    var education: [EducationEntry]
    var workExperience: [WorkExperienceEntry]
    var skills: [SkillCategory]
    var projects: [Project]
    var certificates: [Certificate]
    var languages: [Language]
    var interests: [String]
    var lastUpdated: Date
    
    init() {
        self.personalInfo = PersonalInfo()
        self.education = []
        self.workExperience = []
        self.skills = []
        self.projects = []
        self.certificates = []
        self.languages = []
        self.interests = []
        self.lastUpdated = Date()
    }
}

struct PersonalInfo: Codable {
    var firstName: String
    var lastName: String
    var title: String
    var email: String
    var phone: String
    var address: Address
    var dateOfBirth: Date?
    var profileImageData: Data?
    
    init() {
        self.firstName = ""
        self.lastName = ""
        self.title = ""
        self.email = ""
        self.phone = ""
        self.address = Address()
        self.dateOfBirth = nil
        self.profileImageData = nil
    }
}

struct Address: Codable {
    var street: String
    var city: String
    var postalCode: String
    var country: String
    
    init() {
        self.street = ""
        self.city = ""
        self.postalCode = ""
        self.country = ""
    }
}

struct EducationEntry: Codable, Identifiable {
    let id = UUID()
    var institution: String
    var degree: String
    var fieldOfStudy: String
    var startDate: Date
    var endDate: Date?
    var isCurrentlyStudying: Bool
    var grade: String
    var description: String
    
    init() {
        self.institution = ""
        self.degree = ""
        self.fieldOfStudy = ""
        self.startDate = Date()
        self.endDate = nil
        self.isCurrentlyStudying = false
        self.grade = ""
        self.description = ""
    }
}

struct WorkExperienceEntry: Codable, Identifiable {
    let id = UUID()
    var company: String
    var position: String
    var startDate: Date
    var endDate: Date?
    var isCurrentJob: Bool
    var description: String
    var achievements: [String]
    
    init() {
        self.company = ""
        self.position = ""
        self.startDate = Date()
        self.endDate = nil
        self.isCurrentJob = false
        self.description = ""
        self.achievements = []
    }
}

struct SkillCategory: Codable, Identifiable {
    let id = UUID()
    var categoryName: String
    var skills: [Skill]
    
    init(categoryName: String = "") {
        self.categoryName = categoryName
        self.skills = []
    }
}

struct Skill: Codable, Identifiable {
    let id = UUID()
    var name: String
    var proficiencyLevel: ProficiencyLevel
    
    init(name: String = "", proficiencyLevel: ProficiencyLevel = .beginner) {
        self.name = name
        self.proficiencyLevel = proficiencyLevel
    }
}

enum ProficiencyLevel: String, CaseIterable, Codable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case expert = "Expert"
    
    var localizedString: String {
        switch self {
        case .beginner: return NSLocalizedString("skill.level.beginner", comment: "")
        case .intermediate: return NSLocalizedString("skill.level.intermediate", comment: "")
        case .advanced: return NSLocalizedString("skill.level.advanced", comment: "")
        case .expert: return NSLocalizedString("skill.level.expert", comment: "")
        }
    }
}

struct Project: Codable, Identifiable {
    let id = UUID()
    var name: String
    var description: String
    var startDate: Date
    var endDate: Date?
    var isOngoing: Bool
    var technologies: [String]
    var url: String?
    
    init() {
        self.name = ""
        self.description = ""
        self.startDate = Date()
        self.endDate = nil
        self.isOngoing = false
        self.technologies = []
        self.url = nil
    }
}

struct Certificate: Codable, Identifiable {
    let id = UUID()
    var name: String
    var issuingOrganization: String
    var issueDate: Date
    var expirationDate: Date?
    var credentialId: String?
    var credentialUrl: String?
    
    init() {
        self.name = ""
        self.issuingOrganization = ""
        self.issueDate = Date()
        self.expirationDate = nil
        self.credentialId = nil
        self.credentialUrl = nil
    }
}

struct Language: Codable, Identifiable {
    let id = UUID()
    var name: String
    var proficiencyLevel: LanguageProficiency
    
    init(name: String = "", proficiencyLevel: LanguageProficiency = .elementary) {
        self.name = name
        self.proficiencyLevel = proficiencyLevel
    }
}

enum LanguageProficiency: String, CaseIterable, Codable {
    case elementary = "Elementary"
    case intermediate = "Intermediate"
    case upperIntermediate = "Upper Intermediate"
    case advanced = "Advanced"
    case proficient = "Proficient"
    case native = "Native"
    
    var localizedString: String {
        switch self {
        case .elementary: return NSLocalizedString("language.level.elementary", comment: "")
        case .intermediate: return NSLocalizedString("language.level.intermediate", comment: "")
        case .upperIntermediate: return NSLocalizedString("language.level.upper_intermediate", comment: "")
        case .advanced: return NSLocalizedString("language.level.advanced", comment: "")
        case .proficient: return NSLocalizedString("language.level.proficient", comment: "")
        case .native: return NSLocalizedString("language.level.native", comment: "")
        }
    }
}