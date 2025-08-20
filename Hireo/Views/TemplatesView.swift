//
//  TemplatesView.swift
//  Hireo
//
//  Created by Benedikt Held on 19.08.25.
//

import SwiftUI

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
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(dataManager.cvTemplates) { template in
                    CVTemplateCard(template: template)
                }
            }
            .padding()
        }
    }
}

struct CoverLetterTemplatesTab: View {
    @EnvironmentObject private var dataManager: DataManager
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(dataManager.coverLetterTemplates) { template in
                    CoverLetterTemplateCard(template: template)
                }
            }
            .padding()
        }
    }
}

struct CVTemplateCard: View {
    let template: CVTemplate
    @EnvironmentObject private var dataManager: DataManager
    @State private var showingTemplateCustomization = false
    @State private var showingPDFPreview = false
    @State private var generatedPDFData: Data?
    @State private var isGeneratingPreview = false
    @State private var errorMessage: String?
    @State private var showingError = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Template Preview
            Button(action: {
                generatePreview()
            }) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(height: 120)
                    .overlay(
                        VStack {
                            if isGeneratingPreview {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Generating...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 40))
                                    .foregroundColor(Color(hex: template.colorSchemes.first?.primaryColor ?? "#007AFF"))
                                Text("Tap to Preview")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    )
            }
            .disabled(isGeneratingPreview || dataManager.userProfile == nil)
            
            VStack(spacing: 4) {
                Text(template.name)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                
                Text(template.category.localizedString)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !template.description.isEmpty {
                    Text(template.description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            
            VStack(spacing: 8) {
                Button("Customize & Use") {
                    showingTemplateCustomization = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(dataManager.userProfile == nil)
                
                if dataManager.userProfile == nil {
                    Text("Complete profile first")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .cardStyle()
        .sheet(isPresented: $showingTemplateCustomization) {
            CVTemplateCustomizationView(template: template)
        }
        .sheet(isPresented: $showingPDFPreview) {
            if let pdfData = generatedPDFData {
                PDFPreviewView(pdfData: pdfData, title: "\(template.name) Template Preview")
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }
    
    private func generatePreview() {
        guard let userProfile = dataManager.userProfile else { return }
        
        isGeneratingPreview = true
        
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
}

struct CoverLetterTemplateCard: View {
    let template: CoverLetterTemplate
    @EnvironmentObject private var dataManager: DataManager
    @State private var showingTemplateCustomization = false
    @State private var showingPDFPreview = false
    @State private var generatedPDFData: Data?
    @State private var isGeneratingPreview = false
    @State private var errorMessage: String?
    @State private var showingError = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Template Preview
            Button(action: {
                generatePreview()
            }) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(height: 120)
                    .overlay(
                        VStack {
                            if isGeneratingPreview {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Generating...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Image(systemName: "envelope")
                                    .font(.system(size: 40))
                                    .foregroundColor(Color(hex: template.colorSchemes.first?.primaryColor ?? "#34C759"))
                                Text("Tap to Preview")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    )
            }
            .disabled(isGeneratingPreview || dataManager.userProfile == nil)
            
            VStack(spacing: 4) {
                Text(template.name)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                
                Text(template.category.localizedString)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !template.description.isEmpty {
                    Text(template.description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            
            VStack(spacing: 8) {
                Button("Customize & Use") {
                    showingTemplateCustomization = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(dataManager.userProfile == nil)
                
                if dataManager.userProfile == nil {
                    Text("Complete profile first")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .cardStyle()
        .sheet(isPresented: $showingTemplateCustomization) {
            CoverLetterTemplateCustomizationView(template: template)
        }
        .sheet(isPresented: $showingPDFPreview) {
            if let pdfData = generatedPDFData {
                PDFPreviewView(pdfData: pdfData, title: "\(template.name) Template Preview")
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }
    
    private func generatePreview() {
        guard let userProfile = dataManager.userProfile else { return }
        
        isGeneratingPreview = true
        
        Task {
            do {
                // Create sample content for preview
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
}

#Preview {
    NavigationStack {
        TemplatesView()
            .environmentObject(DataManager.shared)
    }
}