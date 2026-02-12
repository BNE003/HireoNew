//
//  TemplatesView.swift
//  Hireo
//
//  Created by Benedikt Held on 19.08.25.
//

import SwiftUI
import PDFKit


private enum TemplateSurface: Int, CaseIterable {
    case cv
    case coverLetter
    
    var title: String {
        switch self {
        case .cv:
            return "Resume"
        case .coverLetter:
            return "Cover Letter"
        }
    }
    
    var subtitle: String {
        switch self {
        case .cv:
            return "Choose a layout and create a polished CV in minutes."
        case .coverLetter:
            return "Create a matching letter with modern formatting."
        }
    }
    
    var systemImage: String {
        switch self {
        case .cv:
            return "doc.text"
        case .coverLetter:
            return "envelope.open"
        }
    }
    
    var actionTitle: String {
        switch self {
        case .cv:
            return "Create Resume"
        case .coverLetter:
            return "Create Letter"
        }
    }
}

struct TemplatesView: View {
    @EnvironmentObject private var dataManager: DataManager
    @State private var selectedTab: TemplateSurface = .cv
    @State private var selectedCVTemplate: CVTemplate?
    @State private var selectedCoverLetterTemplate: CoverLetterTemplate?
    @State private var showingCVTemplateDetail = false
    @State private var showingCoverLetterDetail = false
    @State private var showingCVTemplatePicker = false
    @State private var showingCoverLetterTemplatePicker = false
    @State private var animateIn = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.09, green: 0.08, blue: 0.24),
                        Color(red: 0.26, green: 0.24, blue: 0.62),
                        Color(red: 0.72, green: 0.76, blue: 0.98)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 260, height: 260)
                    .blur(radius: 36)
                    .offset(x: -140, y: -280)
                
                Circle()
                    .fill(Color(red: 0.76, green: 0.81, blue: 1).opacity(0.55))
                    .frame(width: 320, height: 320)
                    .blur(radius: 60)
                    .offset(x: 170, y: 300)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        headerSection
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : -18)
                            .animation(.easeOut(duration: 0.35), value: animateIn)
                        
                        typeSwitch
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 16)
                            .animation(.easeOut(duration: 0.4).delay(0.08), value: animateIn)
                        
                        heroCard
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 22)
                            .animation(.spring(response: 0.42, dampingFraction: 0.8).delay(0.14), value: animateIn)
                        
                        librarySection
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 28)
                            .animation(.easeOut(duration: 0.42).delay(0.2), value: animateIn)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Templates")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingCVTemplateDetail) {
                if let template = selectedCVTemplate {
                    CVTemplateDetailView(template: template)
                }
            }
            .sheet(isPresented: $showingCoverLetterDetail) {
                if let template = selectedCoverLetterTemplate {
                    CoverLetterTemplateDetailView(template: template)
                }
            }
            .sheet(isPresented: $showingCVTemplatePicker) {
                CVTemplatePickerSheet { template in
                    selectedCVTemplate = template
                    showingCVTemplateDetail = true
                }
                .environmentObject(dataManager)
            }
            .sheet(isPresented: $showingCoverLetterTemplatePicker) {
                CoverLetterTemplatePickerSheet { template in
                    selectedCoverLetterTemplate = template
                    showingCoverLetterDetail = true
                }
                .environmentObject(dataManager)
            }
            .onAppear {
                animateIn = true
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Hello 👋")
                .font(.system(size: 38, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.92))
            Text(selectedTab.subtitle)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 6)
    }
    
    private var typeSwitch: some View {
        HStack(spacing: 8) {
            ForEach(TemplateSurface.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 14, weight: .semibold))
                        Text(tab.title)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(selectedTab == tab ? Color.white : Color.white.opacity(0.78))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(
                        Capsule()
                            .fill(selectedTab == tab ? Color.white.opacity(0.18) : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(5)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.24), lineWidth: 1))
    }
    
    private var heroCard: some View {
        Button {
            openFeaturedTemplate()
        } label: {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 74, height: 74)
                    .overlay(
                        Image(systemName: selectedTab.systemImage)
                            .font(.system(size: 26, weight: .medium))
                            .foregroundStyle(Color(red: 0.33, green: 0.37, blue: 0.9))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedTab.actionTitle)
                        .font(.system(size: 28, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(red: 0.18, green: 0.2, blue: 0.33))
                    Text("with premium templates")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(red: 0.35, green: 0.38, blue: 0.52))
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color(red: 0.39, green: 0.43, blue: 0.94))
                    .padding(.trailing, 4)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 26)
                    .fill(Color.white.opacity(0.92))
                    .overlay(
                        RoundedRectangle(cornerRadius: 26)
                            .stroke(Color.white.opacity(0.65), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.14), radius: 20, x: 0, y: 10)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var librarySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Library")
                    .font(.system(size: 35, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.95))
                Spacer()
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.9))
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    if selectedTab == .cv {
                        if dataManager.cvDocuments.isEmpty {
                            LibraryEmptyStateCard(
                                title: "No resumes yet",
                                subtitle: "Tap Create Resume to generate your first document.",
                                systemImage: "doc.badge.plus"
                            )
                            .frame(width: 240)
                        } else {
                            ForEach(dataManager.cvDocuments) { document in
                                CVDocumentThumbnailView(document: document)
                                    .frame(width: 176)
                                    .transition(.opacity.combined(with: .scale))
                            }
                        }
                    } else {
                        if dataManager.coverLetterDocuments.isEmpty {
                            LibraryEmptyStateCard(
                                title: "No letters yet",
                                subtitle: "Tap Create Letter to generate your first document.",
                                systemImage: "envelope.badge"
                            )
                            .frame(width: 240)
                        } else {
                            ForEach(dataManager.coverLetterDocuments) { document in
                                CoverLetterDocumentThumbnailView(document: document)
                                    .frame(width: 176)
                                    .transition(.opacity.combined(with: .scale))
                            }
                        }
                    }
                }
                .padding(.vertical, 6)
            }
        }
    }
    
    private func openFeaturedTemplate() {
        switch selectedTab {
        case .cv:
            showingCVTemplatePicker = true
        case .coverLetter:
            showingCoverLetterTemplatePicker = true
        }
    }
}

private struct LibraryEmptyStateCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color(red: 0.39, green: 0.43, blue: 0.94))
            Text(title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(red: 0.16, green: 0.17, blue: 0.28))
            Text(subtitle)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Color(red: 0.4, green: 0.42, blue: 0.54))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.88))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.55), lineWidth: 1)
                )
        )
    }
}

struct CVTemplatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataManager: DataManager
    let onSelect: (CVTemplate) -> Void
    
    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(dataManager.cvTemplates) { template in
                        CVTemplateThumbnail(template: template) {
                            dismiss()
                            DispatchQueue.main.async {
                                onSelect(template)
                            }
                        }
                    }
                }
                .padding(16)
            }
            .navigationTitle("Choose Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CoverLetterTemplatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataManager: DataManager
    let onSelect: (CoverLetterTemplate) -> Void
    
    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(dataManager.coverLetterTemplates) { template in
                        CoverLetterTemplateThumbnail(template: template) {
                            dismiss()
                            DispatchQueue.main.async {
                                onSelect(template)
                            }
                        }
                    }
                }
                .padding(16)
            }
            .navigationTitle("Choose Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Thumbnail Views

struct CVTemplateThumbnail: View {
    let template: CVTemplate
    let onTap: () -> Void
    @State private var isGeneratingThumbnail = false
    @State private var thumbnailPDFData: Data?
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                Group {
                    if isGeneratingThumbnail {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .frame(height: 220)
                            .overlay(
                                ProgressView()
                                    .tint(Color(hex: template.colorSchemes.first?.primaryColor ?? "#007AFF"))
                            )
                    } else if let thumbnailData = thumbnailPDFData {
                        PDFThumbnailView(pdfData: thumbnailData)
                            .frame(height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .frame(height: 220)
                            .overlay(
                                Image(systemName: "doc.text")
                                    .font(.system(size: 30))
                                    .foregroundColor(Color(hex: template.colorSchemes.first?.primaryColor ?? "#007AFF"))
                            )
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(template.name)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(red: 0.16, green: 0.17, blue: 0.28))
                        .lineLimit(1)
                    Text(template.category.rawValue)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(red: 0.4, green: 0.42, blue: 0.54))
                }
                .padding(.horizontal, 3)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.55), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 14, x: 0, y: 8)
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            generateThumbnail()
        }
    }
    
    private func generateThumbnail() {
        guard thumbnailPDFData == nil else { return }
        
        let dummyProfile = createDummyUserProfile()
        isGeneratingThumbnail = true
        
        Task {
            do {
                let pdfDocument = try await PDFGenerationService.shared.generateCV(
                    userProfile: dummyProfile,
                    template: template,
                    customSettings: CVSettings()
                )
                
                guard let pdfData = pdfDocument.dataRepresentation() else { return }
                
                await MainActor.run {
                    self.thumbnailPDFData = pdfData
                    self.isGeneratingThumbnail = false
                }
            } catch {
                await MainActor.run {
                    self.isGeneratingThumbnail = false
                }
            }
        }
    }
}

struct CoverLetterTemplateThumbnail: View {
    let template: CoverLetterTemplate
    let onTap: () -> Void
    @State private var isGeneratingThumbnail = false
    @State private var thumbnailPDFData: Data?
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                Group {
                    if isGeneratingThumbnail {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .frame(height: 220)
                            .overlay(
                                ProgressView()
                                    .tint(Color(hex: template.colorSchemes.first?.primaryColor ?? "#34C759"))
                            )
                    } else if let thumbnailData = thumbnailPDFData {
                        PDFThumbnailView(pdfData: thumbnailData)
                            .frame(height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .frame(height: 220)
                            .overlay(
                                Image(systemName: "envelope")
                                    .font(.system(size: 30))
                                    .foregroundColor(Color(hex: template.colorSchemes.first?.primaryColor ?? "#34C759"))
                            )
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(template.name)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(red: 0.16, green: 0.17, blue: 0.28))
                        .lineLimit(1)
                    Text(template.category.rawValue)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(red: 0.4, green: 0.42, blue: 0.54))
                }
                .padding(.horizontal, 3)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.55), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 14, x: 0, y: 8)
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            generateThumbnail()
        }
    }
    
    private func generateThumbnail() {
        guard thumbnailPDFData == nil else { return }
        
        let dummyProfile = createDummyUserProfile()
        isGeneratingThumbnail = true
        
        Task {
            do {
                let sampleContent = CoverLetterContent()
                
                let pdfDocument = try await PDFGenerationService.shared.generateCoverLetter(
                    userProfile: dummyProfile,
                    template: template,
                    content: sampleContent
                )
                
                guard let pdfData = pdfDocument.dataRepresentation() else { return }
                
                await MainActor.run {
                    self.thumbnailPDFData = pdfData
                    self.isGeneratingThumbnail = false
                }
            } catch {
                await MainActor.run {
                    self.isGeneratingThumbnail = false
                }
            }
        }
    }
}

// MARK: - Detail Views

struct CVTemplateDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataManager: DataManager
    let template: CVTemplate
    @State private var showingTemplateCustomization = false
    @State private var isGenerating = false
    @State private var previewPDFData: Data?
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var showingPDFPreview = false
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Large Preview
                    if let previewData = previewPDFData {
                        PDFPreviewContainer(pdfData: previewData)
                            .frame(height: geometry.size.height * 0.6)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal, 20)
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray6))
                            .frame(height: geometry.size.height * 0.6)
                            .overlay(
                                VStack(spacing: 16) {
                                    Image(systemName: "doc.text")
                                        .font(.system(size: 60, weight: .light))
                                        .foregroundColor(Color(hex: template.colorSchemes.first?.primaryColor ?? "#007AFF"))
                                    
                                    Text(template.name)
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    
                                    Text(template.description)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 40)
                                }
                            )
                            .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        Button(action: generateCV) {
                            HStack {
                                if isGenerating {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                Text(isGenerating ? "Creating..." : "Create Resume")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(hex: template.colorSchemes.first?.primaryColor ?? "#007AFF"))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(isGenerating || dataManager.userProfile == nil)
                        
                        Button("Customize Template") {
                            showingTemplateCustomization = true
                        }
                        .font(.headline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .disabled(dataManager.userProfile == nil)
                        
                        Text("Template preview uses dummy data")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if dataManager.userProfile == nil {
                            Text("Complete your profile first")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                                .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.headline)
                    .fontWeight(.medium)
                }
            }
        }
        .sheet(isPresented: $showingTemplateCustomization) {
            CVTemplateCustomizationView(template: template)
        }
        .sheet(isPresented: $showingPDFPreview) {
            if let pdfData = previewPDFData {
                PDFPreviewView(pdfData: pdfData, title: "\(template.name) CV")
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
        .onAppear {
            generatePreview()
        }
    }
    
    private func generatePreview() {
        let userProfile = createDummyUserProfile()
        
        Task {
            do {
                let pdfDocument = try await PDFGenerationService.shared.generateCV(
                    userProfile: userProfile,
                    template: template,
                    customSettings: CVSettings()
                )
                
                guard let pdfData = pdfDocument.dataRepresentation() else { 
                    print("Failed to get PDF data representation for template: \(template.name)")
                    return 
                }
                
                await MainActor.run {
                    self.previewPDFData = pdfData
                }
            } catch {
                print("Failed to generate preview for template \(template.name): \(error)")
            }
        }
    }
    
    private func generateCV() {
        guard let userProfile = dataManager.userProfile else { return }
        
        isGenerating = true
        
        Task {
            do {
                var cvDocument = CVDocument(
                    userProfileId: userProfile.id,
                    templateId: template.id
                )
                cvDocument.colorScheme = template.colorSchemes.first ?? .blue
                dataManager.saveCVDocument(cvDocument)
                
                let pdfDocument = try await PDFGenerationService.shared.generateCV(
                    userProfile: userProfile,
                    template: template,
                    customSettings: CVSettings()
                )
                
                guard let pdfData = pdfDocument.dataRepresentation() else {
                    throw PDFGenerationError.renderingFailed("Failed to get PDF data")
                }
                
                await MainActor.run {
                    self.previewPDFData = pdfData
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
}

struct CoverLetterTemplateDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataManager: DataManager
    let template: CoverLetterTemplate
    @State private var showingTemplateCustomization = false
    @State private var isGenerating = false
    @State private var previewPDFData: Data?
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var showingPDFPreview = false
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Large Preview
                    if let previewData = previewPDFData {
                        PDFPreviewContainer(pdfData: previewData)
                            .frame(height: geometry.size.height * 0.6)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal, 20)
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray6))
                            .frame(height: geometry.size.height * 0.6)
                            .overlay(
                                VStack(spacing: 16) {
                                    Image(systemName: "envelope")
                                        .font(.system(size: 60, weight: .light))
                                        .foregroundColor(Color(hex: template.colorSchemes.first?.primaryColor ?? "#34C759"))
                                    
                                    Text(template.name)
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    
                                    Text(template.description)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 40)
                                }
                            )
                            .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        Button(action: generateCoverLetter) {
                            HStack {
                                if isGenerating {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "arrow.down.doc.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                Text(isGenerating ? "Generating..." : "Generate Cover Letter")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(hex: template.colorSchemes.first?.primaryColor ?? "#34C759"))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(isGenerating || dataManager.userProfile == nil)
                        
                        Button("Customize Template") {
                            showingTemplateCustomization = true
                        }
                        .font(.headline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .disabled(dataManager.userProfile == nil)
                        
                        if dataManager.userProfile == nil {
                            Text("Complete your profile first")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                                .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.headline)
                    .fontWeight(.medium)
                }
            }
        }
        .sheet(isPresented: $showingTemplateCustomization) {
            CoverLetterTemplateCustomizationView(template: template)
        }
        .sheet(isPresented: $showingPDFPreview) {
            if let pdfData = previewPDFData {
                PDFPreviewView(pdfData: pdfData, title: "\(template.name) Cover Letter")
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
        .onAppear {
            generatePreview()
        }
    }
    
    private func generatePreview() {
        let userProfile = dataManager.userProfile ?? createDummyUserProfile()
        
        Task {
            do {
                let sampleContent = CoverLetterContent()
                
                let pdfDocument = try await PDFGenerationService.shared.generateCoverLetter(
                    userProfile: userProfile,
                    template: template,
                    content: sampleContent
                )
                
                guard let pdfData = pdfDocument.dataRepresentation() else { 
                    print("Failed to get PDF data representation for cover letter template: \(template.name)")
                    return 
                }
                
                await MainActor.run {
                    self.previewPDFData = pdfData
                }
            } catch {
                print("Failed to generate preview for cover letter template \(template.name): \(error)")
            }
        }
    }
    
    private func generateCoverLetter() {
        guard let userProfile = dataManager.userProfile else { return }
        
        isGenerating = true
        
        Task {
            do {
                let sampleContent = CoverLetterContent()
                
                var coverLetterDocument = CoverLetterDocument(
                    userProfileId: userProfile.id,
                    templateId: template.id
                )
                coverLetterDocument.colorScheme = template.colorSchemes.first ?? .blue
                coverLetterDocument.content = sampleContent
                dataManager.saveCoverLetterDocument(coverLetterDocument)
                
                let pdfDocument = try await PDFGenerationService.shared.generateCoverLetter(
                    userProfile: userProfile,
                    template: template,
                    content: sampleContent
                )
                
                guard let pdfData = pdfDocument.dataRepresentation() else {
                    throw PDFGenerationError.renderingFailed("Failed to get PDF data")
                }
                
                await MainActor.run {
                    self.previewPDFData = pdfData
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
}

// MARK: - Helper Views

struct PDFThumbnailView: UIViewRepresentable {
    let pdfData: Data
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.systemBackground
        
        guard let pdfDocument = PDFDocument(data: pdfData),
              let page = pdfDocument.page(at: 0) else {
            return view
        }
        
        let pageFrame = page.bounds(for: .mediaBox)
        let scaleFactor: CGFloat = 120 / max(pageFrame.width, pageFrame.height)
        
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        DispatchQueue.global(qos: .userInitiated).async {
            let targetSize = CGSize(width: pageFrame.width * scaleFactor, height: pageFrame.height * scaleFactor)
            let renderer = UIGraphicsImageRenderer(size: targetSize)
            
            let image = renderer.image { context in
                let cgContext = context.cgContext
                
                // Fill with white background
                cgContext.setFillColor(UIColor.white.cgColor)
                cgContext.fill(CGRect(origin: .zero, size: targetSize))
                
                // Save the current context state
                cgContext.saveGState()
                
                // Transform coordinate system to match PDF coordinate system
                cgContext.translateBy(x: 0, y: targetSize.height)
                cgContext.scaleBy(x: scaleFactor, y: -scaleFactor)
                
                // Draw the PDF page
                page.draw(with: .mediaBox, to: cgContext)
                
                // Restore the context state
                cgContext.restoreGState()
            }
            
            DispatchQueue.main.async {
                imageView.image = image
            }
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

struct PDFPreviewContainer: UIViewRepresentable {
    let pdfData: Data
    
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = UIColor.systemBackground
        
        guard let pdfDocument = PDFDocument(data: pdfData) else {
            let label = UILabel()
            label.text = "Failed to load PDF preview"
            label.textAlignment = .center
            label.textColor = UIColor.secondaryLabel
            label.font = UIFont.systemFont(ofSize: 16)
            label.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(label)
            
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
            ])
            
            return containerView
        }
        
        let pdfView = PDFView()
        pdfView.document = pdfDocument
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = UIColor.systemBackground
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(pdfView)
        
        NSLayoutConstraint.activate([
            pdfView.topAnchor.constraint(equalTo: containerView.topAnchor),
            pdfView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            pdfView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - Helper Functions

func createDummyUserProfile() -> UserProfile {
    var profile = UserProfile()
    
    profile.personalInfo.firstName = "John"
    profile.personalInfo.lastName = "Doe" 
    profile.personalInfo.title = "Software Engineer"
    profile.personalInfo.email = "john.doe@example.com"
    profile.personalInfo.phone = "+1 (555) 123-4567"
    profile.personalInfo.summary = "Experienced software engineer with expertise in iOS development and modern app architecture. Passionate about creating user-friendly applications."
    
    profile.personalInfo.address.street = "123 Tech Street"
    profile.personalInfo.address.city = "San Francisco"
    profile.personalInfo.address.postalCode = "94105"
    profile.personalInfo.address.country = "United States"
    
    var workExp1 = WorkExperienceEntry()
    workExp1.position = "Senior iOS Developer"
    workExp1.company = "Tech Corp"
    workExp1.startDate = Date().addingTimeInterval(-365*24*60*60*2) // 2 years ago
    workExp1.endDate = nil
    workExp1.isCurrentJob = true
    workExp1.description = "Lead iOS development for flagship mobile application with 1M+ users. Implemented new features and maintained code quality."
    workExp1.achievements = [
        "Increased app performance by 30%",
        "Led migration to SwiftUI architecture"
    ]
    
    var workExp2 = WorkExperienceEntry()
    workExp2.position = "iOS Developer"
    workExp2.company = "StartupXYZ"
    workExp2.startDate = Date().addingTimeInterval(-365*24*60*60*4) // 4 years ago
    workExp2.endDate = Date().addingTimeInterval(-365*24*60*60*2) // 2 years ago
    workExp2.isCurrentJob = false
    workExp2.description = "Built iOS applications from ground up and contributed to product development."
    workExp2.achievements = [
        "Delivered 3 successful app launches",
        "Reduced crash rate by 50%"
    ]
    
    profile.workExperience = [workExp1, workExp2]
    
    var education = EducationEntry()
    education.institution = "University of Technology"
    education.degree = "Bachelor of Science"
    education.fieldOfStudy = "Computer Science"
    education.startDate = Date().addingTimeInterval(-365*24*60*60*8) // 8 years ago
    education.endDate = Date().addingTimeInterval(-365*24*60*60*4) // 4 years ago
    education.isCurrentlyStudying = false
    education.grade = "3.8 GPA"
    education.description = "Focused on software engineering and mobile development."
    
    profile.education = [education]
    
    var programmingCategory = SkillCategory(categoryName: "Programming Languages")
    programmingCategory.skills = [
        Skill(name: "Swift", proficiencyLevel: .expert),
        Skill(name: "Objective-C", proficiencyLevel: .advanced),
        Skill(name: "Python", proficiencyLevel: .intermediate),
        Skill(name: "JavaScript", proficiencyLevel: .intermediate)
    ]
    
    var frameworksCategory = SkillCategory(categoryName: "Frameworks & Tools")
    frameworksCategory.skills = [
        Skill(name: "SwiftUI", proficiencyLevel: .expert),
        Skill(name: "UIKit", proficiencyLevel: .expert),
        Skill(name: "Xcode", proficiencyLevel: .expert),
        Skill(name: "Git", proficiencyLevel: .advanced)
    ]
    
    profile.skills = [programmingCategory, frameworksCategory]
    
    var project = Project()
    project.name = "TaskMaster Pro"
    project.description = "A productivity app for task management with advanced scheduling features."
    project.technologies = ["Swift", "SwiftUI", "Core Data"]
    project.startDate = Date().addingTimeInterval(-365*24*60*60*1) // 1 year ago
    project.endDate = Date().addingTimeInterval(-365*24*60*60*0.5) // 6 months ago
    project.isOngoing = false
    project.url = "https://github.com/johndoe/taskmaster"
    
    profile.projects = [project]
    
    var certificate = Certificate()
    certificate.name = "iOS App Development with Swift"
    certificate.issuingOrganization = "Apple"
    certificate.issueDate = Date().addingTimeInterval(-365*24*60*60*1) // 1 year ago
    certificate.expirationDate = nil
    certificate.credentialId = "APPL-iOS-2023"
    
    profile.certificates = [certificate]
    
    profile.languages = [
        Language(name: "English", proficiencyLevel: .native),
        Language(name: "Spanish", proficiencyLevel: .intermediate)
    ]
    
    profile.interests = ["iOS Development", "UI/UX Design", "Machine Learning", "Photography"]
    
    return profile
}

#Preview {
    NavigationStack {
        TemplatesView()
            .environmentObject(DataManager.shared)
    }
}
