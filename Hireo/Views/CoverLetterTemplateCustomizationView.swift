//
//  CoverLetterTemplateCustomizationView.swift
//  Hireo
//
//  Created by Benedikt Held on 19.08.25.
//

import SwiftUI
import PDFKit

struct CoverLetterTemplateCustomizationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataManager: DataManager
    
    let template: CoverLetterTemplate
    @State private var content = CoverLetterContent()
    @State private var selectedColorScheme: ColorScheme = .blue
    @State private var selectedFontFamily: FontFamily = .system
    
    @State private var isGeneratingPreview = false
    @State private var showingPDFPreview = false
    @State private var generatedPDFData: Data?
    @State private var errorMessage: String?
    @State private var showingError = false
    
    var body: some View {
        NavigationStack {
            Form {
                // Template Info Section
                Section("Template") {
                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(Color(hex: template.colorSchemes.first?.primaryColor ?? "#34C759"))
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(template.name)
                                .font(.headline)
                            Text(template.category.localizedString)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                
                // Appearance Section
                Section("Appearance") {
                    // Color Scheme
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Color Scheme")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                            ForEach(template.colorSchemes, id: \.self) { colorScheme in
                                ColorSchemeOption(
                                    colorScheme: colorScheme,
                                    isSelected: selectedColorScheme == colorScheme
                                ) {
                                    selectedColorScheme = colorScheme
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    
                    // Font Family
                    Picker("Font Family", selection: $selectedFontFamily) {
                        ForEach(template.fontFamilies, id: \.self) { fontFamily in
                            Text(fontFamily.localizedString)
                                .tag(fontFamily)
                        }
                    }
                }
                
                // Content Section
                Section("Letter Content") {
                    VStack(spacing: 16) {
                        // Company Information
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recipient Information")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            TextField("Company Name", text: $content.recipientCompany)
                                .textFieldStyle(.roundedBorder)
                            
                            TextField("Contact Person (Optional)", text: Binding(
                                get: { content.recipientName ?? "" },
                                set: { content.recipientName = $0.isEmpty ? nil : $0 }
                            ))
                                .textFieldStyle(.roundedBorder)
                            
                            TextField("Position (Optional)", text: Binding(
                                get: { content.recipientPosition ?? "" },
                                set: { content.recipientPosition = $0.isEmpty ? nil : $0 }
                            ))
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        // Salutation
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Salutation")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            TextField("Dear Hiring Manager,", text: $content.salutation)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        // Introduction
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Introduction")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            TextField("Opening paragraph", text: $content.introduction, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(3...5)
                        }
                        
                        // Body
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Main Body")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            TextField("Main content of your cover letter", text: $content.body, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(5...10)
                        }
                        
                        // Closing
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Closing")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            TextField("Closing paragraph", text: $content.closing, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(2...4)
                        }
                        
                        // Signature
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Signature")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            TextField("Your name", text: $content.signature)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                }
                
                // Actions Section
                Section {
                    VStack(spacing: 16) {
                        Button(action: generatePreview) {
                            HStack {
                                if isGeneratingPreview {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "eye")
                                }
                                Text("Preview Cover Letter")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isGeneratingPreview || dataManager.userProfile == nil)
                        
                        Button(action: createCoverLetterDocument) {
                            HStack {
                                Image(systemName: "plus.circle")
                                Text("Create Cover Letter Document")
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(dataManager.userProfile == nil)
                    }
                }
                
                if dataManager.userProfile == nil {
                    Section {
                        Text("Please complete your profile to customize and generate documents")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Customize Cover Letter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Use Suggestions") {
                        fillWithSuggestions()
                    }
                    .font(.caption)
                }
            }
        }
        .onAppear {
            setupInitialContent()
        }
        .sheet(isPresented: $showingPDFPreview) {
            if let pdfData = generatedPDFData {
                PDFPreviewView(pdfData: pdfData, title: "\(template.name) Cover Letter Preview")
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }
    
    private func setupInitialContent() {
        content.templateId = template.id
        selectedColorScheme = template.colorSchemes.first ?? .blue
        selectedFontFamily = template.fontFamilies.first ?? .system
        
        if let userProfile = dataManager.userProfile {
            content.signature = "\(userProfile.personalInfo.firstName) \(userProfile.personalInfo.lastName)"
        }
        
        fillWithSuggestions()
    }
    
    private func fillWithSuggestions() {
        if content.salutation.isEmpty {
            content.salutation = "Dear Hiring Manager,"
        }
        
        if content.introduction.isEmpty {
            content.introduction = "I am writing to express my strong interest in the position at your company. As a professional with relevant experience, I believe I would be a valuable addition to your team."
        }
        
        if content.body.isEmpty {
            content.body = "Throughout my career, I have developed skills and expertise that align well with your requirements. I am passionate about contributing to innovative projects and would welcome the opportunity to bring my experience to your organization. My background includes relevant experience that would benefit your team."
        }
        
        if content.closing.isEmpty {
            content.closing = "I look forward to hearing from you and would welcome the opportunity to discuss how I can contribute to your team. Thank you for considering my application."
        }
    }
    
    private func generatePreview() {
        guard let userProfile = dataManager.userProfile else { return }
        
        isGeneratingPreview = true
        
        Task {
            do {
                let pdfDocument = try await PDFGenerationService.shared.generateCoverLetter(
                    userProfile: userProfile,
                    template: template,
                    content: content
                )
                
                guard let pdfData = pdfDocument.dataRepresentation() else {
                    throw PDFGenerationError.renderingFailed("Failed to get PDF data")
                }
                
                await MainActor.run {
                    self.generatedPDFData = pdfData
                    self.showingPDFPreview = true
                    self.isGeneratingPreview = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showingError = true
                    self.isGeneratingPreview = false
                }
            }
        }
    }
    
    private func createCoverLetterDocument() {
        guard let userProfile = dataManager.userProfile else { return }
        
        // Create a new cover letter document with the customized content
        var coverLetterDocument = CoverLetterDocument(
            userProfileId: userProfile.id,
            templateId: template.id
        )
        coverLetterDocument.colorScheme = selectedColorScheme
        coverLetterDocument.fontFamily = selectedFontFamily
        coverLetterDocument.content = content
        
        // Generate a meaningful filename
        let companyName = content.recipientCompany.isEmpty ? "Company" : content.recipientCompany
        coverLetterDocument.fileName = "CoverLetter_\(companyName)_\(Date().formatted(.dateTime.year().month().day()))"
        
        dataManager.saveCoverLetterDocument(coverLetterDocument)
        dismiss()
    }
}

#Preview {
    let template = CoverLetterTemplate(
        id: "professional",
        name: "Professional",
        description: "Standard business format",
        category: .professional
    )
    
    CoverLetterTemplateCustomizationView(template: template)
        .environmentObject(DataManager.shared)
}