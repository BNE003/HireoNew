//
//  Template.swift
//  Hireo
//
//  Created by Benedikt Held on 19.08.25.
//

import Foundation

struct CVTemplate: Codable, Identifiable {
    let id: String
    var name: String
    var description: String
    var category: TemplateCategory
    var previewImageName: String
    var colorSchemes: [ColorScheme]
    var fontFamilies: [FontFamily]
    var layoutSettings: CVLayoutSettings
    var isBuiltIn: Bool
    
    init(id: String, name: String, description: String = "", category: TemplateCategory = .modern) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.previewImageName = "\(id)_preview"
        self.colorSchemes = [.blue, .gray, .green]
        self.fontFamilies = [.system, .serif, .modern]
        self.layoutSettings = CVLayoutSettings()
        self.isBuiltIn = true
    }
}

struct CoverLetterTemplate: Codable, Identifiable {
    let id: String
    var name: String
    var description: String
    var category: TemplateCategory
    var previewImageName: String
    var colorSchemes: [ColorScheme]
    var fontFamilies: [FontFamily]
    var layoutSettings: CoverLetterLayoutSettings
    var isBuiltIn: Bool
    
    init(id: String, name: String, description: String = "", category: TemplateCategory = .professional) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.previewImageName = "\(id)_preview"
        self.colorSchemes = [.blue, .gray, .green]
        self.fontFamilies = [.system, .serif, .modern]
        self.layoutSettings = CoverLetterLayoutSettings()
        self.isBuiltIn = true
    }
}

enum TemplateCategory: String, CaseIterable, Codable {
    case modern = "Modern"
    case classic = "Classic"
    case creative = "Creative"
    case professional = "Professional"
    case minimal = "Minimal"
    
    var localizedString: String {
        switch self {
        case .modern: return NSLocalizedString("template.category.modern", comment: "")
        case .classic: return NSLocalizedString("template.category.classic", comment: "")
        case .creative: return NSLocalizedString("template.category.creative", comment: "")
        case .professional: return NSLocalizedString("template.category.professional", comment: "")
        case .minimal: return NSLocalizedString("template.category.minimal", comment: "")
        }
    }
}

enum ColorScheme: String, CaseIterable, Codable {
    case blue = "Blue"
    case gray = "Gray"
    case green = "Green"
    case purple = "Purple"
    case red = "Red"
    case orange = "Orange"
    case teal = "Teal"
    case black = "Black"
    
    var primaryColor: String {
        switch self {
        case .blue: return "#007AFF"
        case .gray: return "#8E8E93"
        case .green: return "#34C759"
        case .purple: return "#AF52DE"
        case .red: return "#FF3B30"
        case .orange: return "#FF9500"
        case .teal: return "#5AC8FA"
        case .black: return "#000000"
        }
    }
    
    var secondaryColor: String {
        switch self {
        case .blue: return "#5AC8FA"
        case .gray: return "#C7C7CC"
        case .green: return "#30D158"
        case .purple: return "#BF5AF2"
        case .red: return "#FF453A"
        case .orange: return "#FF9F0A"
        case .teal: return "#64D2FF"
        case .black: return "#48484A"
        }
    }
}

enum FontFamily: String, CaseIterable, Codable {
    case system = "System"
    case serif = "Serif"
    case modern = "Modern"
    case classic = "Classic"
    
    var fontName: String {
        switch self {
        case .system: return "San Francisco"
        case .serif: return "Times New Roman"
        case .modern: return "Helvetica Neue"
        case .classic: return "Georgia"
        }
    }
    
    var localizedString: String {
        switch self {
        case .system: return NSLocalizedString("font.system", comment: "")
        case .serif: return NSLocalizedString("font.serif", comment: "")
        case .modern: return NSLocalizedString("font.modern", comment: "")
        case .classic: return NSLocalizedString("font.classic", comment: "")
        }
    }
}

struct CVLayoutSettings: Codable {
    var headerStyle: HeaderStyle
    var sectionSpacing: Double
    var sidebarWidth: Double?
    var showProfilePicture: Bool
    var showSectionIcons: Bool
    var bulletPointStyle: BulletPointStyle
    
    init() {
        self.headerStyle = .centered
        self.sectionSpacing = 20.0
        self.sidebarWidth = nil
        self.showProfilePicture = true
        self.showSectionIcons = false
        self.bulletPointStyle = .bullet
    }
}

struct CoverLetterLayoutSettings: Codable {
    var headerStyle: HeaderStyle
    var paragraphSpacing: Double
    var marginSize: Double
    var showCompanyLogo: Bool
    var dateFormat: DateFormat
    
    init() {
        self.headerStyle = .left
        self.paragraphSpacing = 15.0
        self.marginSize = 25.0
        self.showCompanyLogo = false
        self.dateFormat = .long
    }
}

enum HeaderStyle: String, CaseIterable, Codable {
    case left = "Left"
    case centered = "Centered"
    case right = "Right"
    case split = "Split"
}

enum BulletPointStyle: String, CaseIterable, Codable {
    case bullet = "Bullet"
    case dash = "Dash"
    case arrow = "Arrow"
    case none = "None"
}

enum DateFormat: String, CaseIterable, Codable {
    case short = "Short"
    case medium = "Medium"
    case long = "Long"
}