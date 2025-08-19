//
//  Document.swift
//  Hireo
//
//  Created by Benedikt Held on 19.08.25.
//

import Foundation

struct CVDocument: Codable, Identifiable {
    let id = UUID()
    var userProfileId: UUID
    var applicationId: UUID?
    var templateId: String
    var colorScheme: ColorScheme
    var fontFamily: FontFamily
    var customSettings: CVSettings
    var fileName: String
    var createdAt: Date
    var lastModified: Date
    
    init(userProfileId: UUID, applicationId: UUID? = nil, templateId: String = "modern") {
        self.userProfileId = userProfileId
        self.applicationId = applicationId
        self.templateId = templateId
        self.colorScheme = .blue
        self.fontFamily = .system
        self.customSettings = CVSettings()
        self.fileName = "CV_\(Date().formatted(.dateTime.year().month().day()))"
        self.createdAt = Date()
        self.lastModified = Date()
    }
}

struct CoverLetterDocument: Codable, Identifiable {
    let id = UUID()
    var userProfileId: UUID
    var applicationId: UUID?
    var templateId: String
    var colorScheme: ColorScheme
    var fontFamily: FontFamily
    var content: CoverLetterContent
    var fileName: String
    var createdAt: Date
    var lastModified: Date
    
    init(userProfileId: UUID, applicationId: UUID? = nil, templateId: String = "professional") {
        self.userProfileId = userProfileId
        self.applicationId = applicationId
        self.templateId = templateId
        self.colorScheme = .blue
        self.fontFamily = .system
        self.content = CoverLetterContent()
        self.fileName = "CoverLetter_\(Date().formatted(.dateTime.year().month().day()))"
        self.createdAt = Date()
        self.lastModified = Date()
    }
}

protocol DocumentExportable {
    var fileName: String { get }
    var createdAt: Date { get }
    var lastModified: Date { get }
    
    func generatePDF() async throws -> Data
    func getPreviewImage() async -> Data?
}

extension CVDocument: DocumentExportable {
    func generatePDF() async throws -> Data {
        throw DocumentError.notImplemented
    }
    
    func getPreviewImage() async -> Data? {
        return nil
    }
}

extension CoverLetterDocument: DocumentExportable {
    func generatePDF() async throws -> Data {
        throw DocumentError.notImplemented
    }
    
    func getPreviewImage() async -> Data? {
        return nil
    }
}

enum DocumentError: LocalizedError {
    case notImplemented
    case invalidTemplate
    case missingUserData
    case exportFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return NSLocalizedString("document.error.not_implemented", comment: "")
        case .invalidTemplate:
            return NSLocalizedString("document.error.invalid_template", comment: "")
        case .missingUserData:
            return NSLocalizedString("document.error.missing_user_data", comment: "")
        case .exportFailed(let message):
            return NSLocalizedString("document.error.export_failed", comment: "") + ": \(message)"
        }
    }
}