//
//  CoverLetterDocumentDetailView.swift
//  Hireo
//
//  Created by Benedikt Held on 19.08.25.
//

import SwiftUI
import PDFKit

struct CoverLetterDocumentDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataManager: DataManager
    
    let document: CoverLetterDocument
    @State private var showingPDFPreview = false
    @State private var generatedPDFData: Data?
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var showingError = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Document Info Section
                    documentInfoSection
                    
                    // Template & Settings Section
                    templateSettingsSection
                    
                    // Content Preview Section
                    contentPreviewSection
                    
                    // Application Link Section
                    if let application = linkedApplication {
                        applicationLinkSection(application: application)
                    }
                    
                    // Actions Section
                    actionsSection
                }
                .padding()
            }
            .navigationTitle("Cover Letter")
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
                PDFPreviewView(pdfData: pdfData, title: document.fileName)
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }
    
    private var documentInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(document.fileName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let template = dataManager.getCoverLetterTemplate(by: document.templateId) {
                        Text(template.name)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Circle()
                    .fill(Color(hex: document.colorScheme.primaryColor))
                    .frame(width: 20, height: 20)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                InfoRow(label: "Created", value: document.createdAt.formatted(date: .abbreviated, time: .shortened))
                InfoRow(label: "Last Modified", value: document.lastModified.formatted(date: .abbreviated, time: .shortened))
                InfoRow(label: "Template", value: dataManager.getCoverLetterTemplate(by: document.templateId)?.name ?? "Unknown")
                InfoRow(label: "Color Scheme", value: document.colorScheme.rawValue)
                InfoRow(label: "Font Family", value: document.fontFamily.localizedString)
                
                if !document.content.recipientCompany.isEmpty {
                    InfoRow(label: "Recipient", value: document.content.recipientCompany)
                }
            }
        }
        .padding()
        .cardStyle()
    }
    
    private var templateSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Template Settings")
                .font(.headline)
            
            if let template = dataManager.getCoverLetterTemplate(by: document.templateId) {
                VStack(alignment: .leading, spacing: 12) {
                    InfoRow(label: "Category", value: template.category.localizedString)
                    InfoRow(label: "Header Style", value: template.layoutSettings.headerStyle.rawValue)
                    InfoRow(label: "Margin Size", value: "\(Int(template.layoutSettings.marginSize))pt")
                    InfoRow(label: "Paragraph Spacing", value: "\(Int(template.layoutSettings.paragraphSpacing))pt")
                }
            }
        }
        .padding()
        .cardStyle()
    }
    
    private var contentPreviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Content Preview")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                if !document.content.salutation.isEmpty {
                    ContentPreviewItem(label: "Salutation", content: document.content.salutation)
                }
                
                if !document.content.introduction.isEmpty {
                    ContentPreviewItem(label: "Introduction", content: document.content.introduction)
                }
                
                if !document.content.body.isEmpty {
                    ContentPreviewItem(label: "Main Body", content: document.content.body)
                }
                
                if !document.content.closing.isEmpty {
                    ContentPreviewItem(label: "Closing", content: document.content.closing)
                }
                
                if !document.content.signature.isEmpty {
                    ContentPreviewItem(label: "Signature", content: document.content.signature)
                }
            }
        }
        .padding()
        .cardStyle()
    }
    
    private func applicationLinkSection(application: Application) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Linked Application")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(application.position)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(application.companyName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Applied: \(application.applicationDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                StatusBadge(status: application.status)
            }
        }
        .padding()
        .cardStyle()
    }
    
    private var actionsSection: some View {
        VStack(spacing: 16) {
            Button(action: generatePreview) {
                HStack {
                    if isGenerating {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "eye")
                    }
                    Text("Preview PDF")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isGenerating || dataManager.userProfile == nil)
            
            HStack(spacing: 16) {
                Button(action: exportPDF) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(isGenerating || dataManager.userProfile == nil)
                
                Button(action: duplicateDocument) {
                    HStack {
                        Image(systemName: "doc.on.doc")
                        Text("Duplicate")
                    }
                }
                .buttonStyle(.bordered)
            }
            
            if dataManager.userProfile == nil {
                Text("Please complete your profile to generate PDFs")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .cardStyle()
    }
    
    private var linkedApplication: Application? {
        guard let applicationId = document.applicationId else { return nil }
        return dataManager.applications.first { $0.id == applicationId }
    }
    
    private func generatePreview() {
        guard let userProfile = dataManager.userProfile else { return }
        
        isGenerating = true
        
        Task {
            do {
                let pdfData = try await document.generatePDF()
                
                await MainActor.run {
                    self.generatedPDFData = pdfData
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
    
    private func exportPDF() {
        isGenerating = true
        
        Task {
            do {
                let pdfData = try await document.generatePDF()
                
                await MainActor.run {
                    let activityVC = UIActivityViewController(activityItems: [pdfData], applicationActivities: nil)
                    
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first,
                       let rootVC = window.rootViewController {
                        rootVC.present(activityVC, animated: true)
                    }
                    
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
    
    private func duplicateDocument() {
        guard let userProfile = dataManager.userProfile else { return }
        
        var newDocument = CoverLetterDocument(
            userProfileId: userProfile.id,
            applicationId: document.applicationId,
            templateId: document.templateId
        )
        
        newDocument.colorScheme = document.colorScheme
        newDocument.fontFamily = document.fontFamily
        newDocument.content = document.content
        newDocument.fileName = "\(document.fileName) Copy"
        
        dataManager.saveCoverLetterDocument(newDocument)
    }
}

struct ContentPreviewItem: View {
    let label: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text(content)
                .font(.body)
                .lineLimit(3)
                .padding(.leading, 8)
        }
    }
}

#Preview {
    let sampleDocument = CoverLetterDocument(
        userProfileId: UUID(),
        templateId: "professional"
    )
    
    NavigationStack {
        CoverLetterDocumentDetailView(document: sampleDocument)
            .environmentObject(DataManager.shared)
    }
}