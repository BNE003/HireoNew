//
//  CVTemplateCustomizationView.swift
//  Hireo
//
//  Created by Benedikt Held on 19.08.25.
//

import SwiftUI
import PDFKit

struct CVTemplateCustomizationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataManager: DataManager
    
    let template: CVTemplate
    @State private var customSettings = CVSettings()
    @State private var selectedColorScheme: ColorScheme = .blue
    @State private var selectedFontFamily: FontFamily = .system
    @State private var includedSections: Set<CVSection> = Set(CVSection.allCases)
    @State private var sectionOrder: [CVSection] = CVSection.allCases
    
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
                        Image(systemName: "doc.text")
                            .foregroundColor(Color(hex: template.colorSchemes.first?.primaryColor ?? "#007AFF"))
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
                
                // Sections to Include
                Section("Sections to Include") {
                    ForEach(CVSection.allCases, id: \.self) { section in
                        HStack {
                            Button(action: {
                                toggleSection(section)
                            }) {
                                HStack {
                                    Image(systemName: includedSections.contains(section) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(includedSections.contains(section) ? .blue : .gray)
                                    
                                    Text(section.localizedString)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                // Section Order
                Section("Section Order") {
                    ForEach(sectionOrder.filter { includedSections.contains($0) }, id: \.self) { section in
                        HStack {
                            Image(systemName: "line.3.horizontal")
                                .foregroundColor(.gray)
                            
                            Text(section.localizedString)
                            
                            Spacer()
                        }
                    }
                    .onMove(perform: moveSections)
                }
                
                // Generate Section
                Section {
                    Button(action: generateCV) {
                        HStack {
                            if isGeneratingPreview {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.down.doc.fill")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            Text(isGeneratingPreview ? "Generating..." : "Generate CV")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(hex: template.colorSchemes.first?.primaryColor ?? "#007AFF"))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .disabled(isGeneratingPreview || dataManager.userProfile == nil)
                    .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                }
                
                if dataManager.userProfile == nil {
                    Section {
                        Text("Please complete your profile to customize and generate documents")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Customize Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            setupInitialSettings()
        }
        .sheet(isPresented: $showingPDFPreview) {
            if let pdfData = generatedPDFData {
                PDFPreviewView(pdfData: pdfData, title: "\(template.name) CV Preview")
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }
    
    private func setupInitialSettings() {
        customSettings = CVSettings()
        selectedColorScheme = template.colorSchemes.first ?? .blue
        selectedFontFamily = template.fontFamilies.first ?? .system
        includedSections = Set(CVSection.allCases)
        sectionOrder = CVSection.allCases
    }
    
    private func toggleSection(_ section: CVSection) {
        if includedSections.contains(section) {
            includedSections.remove(section)
        } else {
            includedSections.insert(section)
        }
        updateCustomSettings()
    }
    
    private func moveSections(from source: IndexSet, to destination: Int) {
        let activeSections = sectionOrder.filter { includedSections.contains($0) }
        var newOrder = activeSections
        newOrder.move(fromOffsets: source, toOffset: destination)
        
        // Rebuild full section order maintaining inactive sections
        var fullOrder: [CVSection] = []
        var activeIndex = 0
        
        for section in sectionOrder {
            if includedSections.contains(section) {
                fullOrder.append(newOrder[activeIndex])
                activeIndex += 1
            } else {
                fullOrder.append(section)
            }
        }
        
        sectionOrder = fullOrder
        updateCustomSettings()
    }
    
    private func updateCustomSettings() {
        customSettings.colorScheme = selectedColorScheme.rawValue
        customSettings.fontFamily = selectedFontFamily.rawValue
        customSettings.includedSections = Array(includedSections)
        customSettings.sectionOrder = sectionOrder
    }
    
    private func generatePreview() {
        guard let userProfile = dataManager.userProfile else { return }
        
        isGeneratingPreview = true
        updateCustomSettings()
        
        Task {
            do {
                let pdfDocument = try await PDFGenerationService.shared.generateCV(
                    userProfile: userProfile,
                    template: template,
                    customSettings: customSettings
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
    
    private func generateCV() {
        guard let userProfile = dataManager.userProfile else { return }
        
        isGeneratingPreview = true
        updateCustomSettings()
        
        Task {
            do {
                let pdfDocument = try await PDFGenerationService.shared.generateCV(
                    userProfile: userProfile,
                    template: template,
                    customSettings: customSettings
                )
                
                guard let pdfData = pdfDocument.dataRepresentation() else {
                    throw PDFGenerationError.renderingFailed("Failed to get PDF data")
                }
                
                await MainActor.run {
                    self.generatedPDFData = pdfData
                    self.showingPDFPreview = true
                    self.isGeneratingPreview = false
                    
                    // Also save the document
                    var cvDocument = CVDocument(
                        userProfileId: userProfile.id,
                        templateId: template.id
                    )
                    cvDocument.colorScheme = selectedColorScheme
                    cvDocument.fontFamily = selectedFontFamily
                    cvDocument.customSettings = customSettings
                    dataManager.saveCVDocument(cvDocument)
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
    
    private func createCVDocument() {
        guard let userProfile = dataManager.userProfile else { return }
        
        updateCustomSettings()
        
        // Create a new CV document with the customized settings
        var cvDocument = CVDocument(
            userProfileId: userProfile.id,
            templateId: template.id
        )
        cvDocument.colorScheme = selectedColorScheme
        cvDocument.fontFamily = selectedFontFamily
        cvDocument.customSettings = customSettings
        
        dataManager.saveCVDocument(cvDocument)
        dismiss()
    }
}

struct ColorSchemeOption: View {
    let colorScheme: ColorScheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Circle()
                    .fill(Color(hex: colorScheme.primaryColor))
                    .frame(width: 30, height: 30)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                    )
                
                Text(colorScheme.rawValue)
                    .font(.caption2)
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(.plain)
    }
}

extension Color {
    init(hex: String) {
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
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    let template = CVTemplate(id: "modern", name: "Modern Professional", description: "Clean and contemporary design")
    
    CVTemplateCustomizationView(template: template)
        .environmentObject(DataManager.shared)
}