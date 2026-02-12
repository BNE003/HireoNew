//
//  CVDocumentDetailView.swift
//  Hireo
//
//  Created by Benedikt Held on 19.08.25.
//

import SwiftUI
import PDFKit

struct CVDocumentDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataManager: DataManager
    
    let document: CVDocument
    @State private var showingPDFPreview = false
    @State private var generatedPDFData: Data?
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var showingProfileEdit = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Document Info Section
                    documentInfoSection
                    
                    // Template & Settings Section
                    templateSettingsSection
                    
                    // Application Link Section
                    if let application = linkedApplication {
                        applicationLinkSection(application: application)
                    }
                    
                    // Actions Section
                    actionsSection
                }
                .padding()
            }
            .navigationTitle("CV Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showingProfileEdit = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingPDFPreview) {
            if let pdfData = generatedPDFData {
                PDFPreviewView(pdfData: pdfData, title: document.fileName)
            }
        }
        .sheet(isPresented: $showingProfileEdit) {
            ProfileEditView()
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
                    
                    if let template = dataManager.getCVTemplate(by: document.templateId) {
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
                InfoRow(label: "Template", value: dataManager.getCVTemplate(by: document.templateId)?.name ?? "Unknown")
                InfoRow(label: "Color Scheme", value: document.colorScheme.rawValue)
                InfoRow(label: "Font Family", value: document.fontFamily.localizedString)
            }
        }
        .padding()
        .cardStyle()
    }
    
    private var templateSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Template Settings")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Included Sections")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(document.customSettings.includedSections, id: \.self) { section in
                            Text(section.localizedString)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(hex: document.colorScheme.primaryColor).opacity(0.1))
                                .foregroundColor(Color(hex: document.colorScheme.primaryColor))
                                .cornerRadius(8)
                        }
                    }
                }
                
                if document.customSettings.includedSections.count != CVSection.allCases.count {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Excluded Sections")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(CVSection.allCases.filter { !document.customSettings.includedSections.contains($0) }, id: \.self) { section in
                                Text(section.localizedString)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.gray.opacity(0.1))
                                    .foregroundColor(.gray)
                                    .cornerRadius(8)
                            }
                        }
                    }
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
        
        var newDocument = CVDocument(
            userProfileId: userProfile.id,
            applicationId: document.applicationId,
            templateId: document.templateId
        )
        
        newDocument.colorScheme = document.colorScheme
        newDocument.fontFamily = document.fontFamily
        newDocument.customSettings = document.customSettings
        newDocument.fileName = "\(document.fileName) Copy"
        
        dataManager.saveCVDocument(newDocument)
    }
}

// Flow Layout for dynamic content
struct FlowLayout: Layout {
    let spacing: CGFloat
    
    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return layout(sizes: sizes, in: proposal.replacingUnspecifiedDimensions()).size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let positions = layout(sizes: sizes, in: proposal.replacingUnspecifiedDimensions()).positions
        
        for (subview, position) in zip(subviews, positions) {
            subview.place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }
    
    private func layout(sizes: [CGSize], in bounds: CGSize) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var currentRow: [CGSize] = []
        var currentRowWidth: CGFloat = 0
        var currentY: CGFloat = 0
        var maxWidth: CGFloat = 0
        
        for size in sizes {
            if currentRowWidth + size.width + (currentRow.isEmpty ? 0 : spacing) <= bounds.width {
                // Add to current row
                currentRow.append(size)
                currentRowWidth += size.width + (currentRow.count > 1 ? spacing : 0)
            } else {
                // Place current row and start new one
                placeRow(currentRow, at: currentY, maxWidth: currentRowWidth, positions: &positions)
                maxWidth = max(maxWidth, currentRowWidth)
                
                currentY += (currentRow.first?.height ?? 0) + spacing
                currentRow = [size]
                currentRowWidth = size.width
            }
        }
        
        // Place final row
        if !currentRow.isEmpty {
            placeRow(currentRow, at: currentY, maxWidth: currentRowWidth, positions: &positions)
            maxWidth = max(maxWidth, currentRowWidth)
            currentY += currentRow.first?.height ?? 0
        }
        
        return (CGSize(width: maxWidth, height: currentY), positions)
    }
    
    private func placeRow(_ row: [CGSize], at y: CGFloat, maxWidth: CGFloat, positions: inout [CGPoint]) {
        var x: CGFloat = 0
        for size in row {
            positions.append(CGPoint(x: x, y: y))
            x += size.width + spacing
        }
    }
}

#Preview {
    let sampleDocument = CVDocument(
        userProfileId: UUID(),
        templateId: "modern"
    )
    
    NavigationStack {
        CVDocumentDetailView(document: sampleDocument)
            .environmentObject(DataManager.shared)
    }
}
