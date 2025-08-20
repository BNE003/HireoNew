//
//  ApplicationDetailView.swift
//  Hireo
//
//  Created by Benedikt Held on 19.08.25.
//

import SwiftUI
import PDFKit

struct ApplicationDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataManager: DataManager
    
    let application: Application
    @State private var isGeneratingCV = false
    @State private var isGeneratingCoverLetter = false
    @State private var showingPDFPreview = false
    @State private var generatedPDFData: Data?
    @State private var pdfTitle = ""
    @State private var errorMessage: String?
    @State private var showingError = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Application Info Section
                    applicationInfoSection
                    
                    // Document Generation Section
                    documentGenerationSection
                    
                    // Timeline Section
                    timelineSection
                }
                .padding()
            }
            .navigationTitle("Application Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        // TODO: Navigate to edit view
                    }
                }
            }
        }
        .sheet(isPresented: $showingPDFPreview) {
            if let pdfData = generatedPDFData {
                PDFPreviewView(pdfData: pdfData, title: pdfTitle)
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }
    
    private var applicationInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(application.position)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(application.companyName)
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                StatusBadge(status: application.status)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                InfoRow(label: "Application Date", value: application.applicationDate.formatted(date: .abbreviated, time: .omitted))
                InfoRow(label: "Created", value: application.createdAt.formatted(date: .abbreviated, time: .shortened))
                InfoRow(label: "Last Modified", value: application.lastModified.formatted(date: .abbreviated, time: .shortened))
                
                if let contactPerson = application.contactPerson, !contactPerson.name.isEmpty {
                    InfoRow(label: "Contact Person", value: "\(contactPerson.name) - \(contactPerson.position)")
                    if let email = contactPerson.email, !email.isEmpty {
                        InfoRow(label: "Email", value: email)
                    }
                }
                
                if !application.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(application.notes)
                            .font(.body)
                    }
                }
            }
        }
        .padding()
        .cardStyle()
    }
    
    private var documentGenerationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Documents")
                .font(.headline)
            
            VStack(spacing: 12) {
                // CV Generation
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CV / Resume")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Generate a customized resume for this application")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: generateCV) {
                        HStack(spacing: 4) {
                            if isGeneratingCV {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "doc.text")
                            }
                            Text("Generate CV")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isGeneratingCV || dataManager.userProfile == nil)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Cover Letter Generation
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Cover Letter")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Generate a customized cover letter for this application")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: generateCoverLetter) {
                        HStack(spacing: 4) {
                            if isGeneratingCoverLetter {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "envelope")
                            }
                            Text("Generate Letter")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isGeneratingCoverLetter || dataManager.userProfile == nil)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            if dataManager.userProfile == nil {
                Text("Please complete your profile to generate documents")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.top, 8)
            }
        }
        .padding()
        .cardStyle()
    }
    
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Timeline")
                .font(.headline)
            
            VStack(spacing: 0) {
                TimelineEntry(
                    title: "Application Created",
                    date: application.createdAt,
                    isLast: false
                )
                
                if application.status != .draft {
                    TimelineEntry(
                        title: "Application \(application.status.localizedString)",
                        date: application.lastModified,
                        isLast: true
                    )
                }
            }
        }
        .padding()
        .cardStyle()
    }
    
    private func generateCV() {
        guard let userProfile = dataManager.userProfile else { return }
        
        isGeneratingCV = true
        
        Task {
            do {
                let cvTemplate = dataManager.getCVTemplate(by: "modern") ?? dataManager.cvTemplates.first!
                let customSettings = application.customCVSettings ?? CVSettings()
                
                let pdfDocument = try await PDFGenerationService.shared.generateCV(
                    userProfile: userProfile,
                    template: cvTemplate,
                    customSettings: customSettings
                )
                
                guard let pdfData = pdfDocument.dataRepresentation() else {
                    throw PDFGenerationError.renderingFailed("Failed to get PDF data")
                }
                
                await MainActor.run {
                    self.generatedPDFData = pdfData
                    self.pdfTitle = "CV - \(application.position) at \(application.companyName)"
                    self.showingPDFPreview = true
                    self.isGeneratingCV = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showingError = true
                    self.isGeneratingCV = false
                }
            }
        }
    }
    
    private func generateCoverLetter() {
        guard let userProfile = dataManager.userProfile else { return }
        
        isGeneratingCoverLetter = true
        
        Task {
            do {
                let coverLetterTemplate = dataManager.getCoverLetterTemplate(by: "professional") ?? dataManager.coverLetterTemplates.first!
                
                // Create default cover letter content for this application
                var content = application.customCoverLetterContent ?? CoverLetterContent()
                content.recipientCompany = application.companyName
                content.salutation = "Dear Hiring Manager,"
                content.introduction = "I am writing to express my strong interest in the \(application.position) position at \(application.companyName)."
                content.body = "With my background and experience, I believe I would be a valuable addition to your team. Please find my resume attached for your review."
                content.closing = "I look forward to hearing from you and would welcome the opportunity to discuss how I can contribute to \(application.companyName)."
                content.signature = "\(userProfile.personalInfo.firstName) \(userProfile.personalInfo.lastName)"
                
                let pdfDocument = try await PDFGenerationService.shared.generateCoverLetter(
                    userProfile: userProfile,
                    template: coverLetterTemplate,
                    content: content
                )
                
                guard let pdfData = pdfDocument.dataRepresentation() else {
                    throw PDFGenerationError.renderingFailed("Failed to get PDF data")
                }
                
                await MainActor.run {
                    self.generatedPDFData = pdfData
                    self.pdfTitle = "Cover Letter - \(application.position) at \(application.companyName)"
                    self.showingPDFPreview = true
                    self.isGeneratingCoverLetter = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showingError = true
                    self.isGeneratingCoverLetter = false
                }
            }
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.body)
            
            Spacer()
        }
    }
}

struct TimelineEntry: View {
    let title: String
    let date: Date
    let isLast: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 10, height: 10)
                
                if !isLast {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2, height: 30)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct PDFPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    let pdfData: Data
    let title: String
    @State private var pdfDocument: PDFDocument?
    @State private var isSharing = false
    
    var body: some View {
        NavigationStack {
            Group {
                if let pdfDocument = pdfDocument {
                    PDFKitView(pdfDocument: pdfDocument)
                } else {
                    ProgressView("Loading PDF...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isSharing = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .disabled(pdfDocument == nil)
                }
            }
        }
        .onAppear {
            pdfDocument = PDFDocument(data: pdfData)
        }
        .sheet(isPresented: $isSharing) {
            if let pdfDocument = pdfDocument {
                ShareSheet(items: [pdfData])
            }
        }
    }
}

struct PDFKitView: UIViewRepresentable {
    let pdfDocument: PDFDocument
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = pdfDocument
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = pdfDocument
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    let sampleApplication = Application(companyName: "Apple Inc.", position: "iOS Developer")
    
    NavigationStack {
        ApplicationDetailView(application: sampleApplication)
            .environmentObject(DataManager.shared)
    }
}