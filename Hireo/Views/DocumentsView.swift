//
//  DocumentsView.swift
//  Hireo
//
//  Created by Benedikt Held on 19.08.25.
//

import SwiftUI
import PDFKit

struct DocumentsView: View {
    @EnvironmentObject private var dataManager: DataManager
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Document Type", selection: $selectedTab) {
                    Text("CVs").tag(0)
                    Text("Cover Letters").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                TabView(selection: $selectedTab) {
                    CVDocumentsTab()
                        .tag(0)
                    
                    CoverLetterDocumentsTab()
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Documents")
        }
    }
}

struct CVDocumentsTab: View {
    @EnvironmentObject private var dataManager: DataManager
    private let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 16)
    ]
    
    var body: some View {
        Group {
            if dataManager.cvDocuments.isEmpty {
                EmptyDocumentsView(type: "CV")
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(dataManager.cvDocuments) { document in
                            CVDocumentThumbnailView(document: document)
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    private func deleteCVDocuments(offsets: IndexSet) {
        for index in offsets {
            dataManager.deleteCVDocument(dataManager.cvDocuments[index])
        }
    }
}

struct CoverLetterDocumentsTab: View {
    @EnvironmentObject private var dataManager: DataManager
    private let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 16)
    ]
    
    var body: some View {
        Group {
            if dataManager.coverLetterDocuments.isEmpty {
                EmptyDocumentsView(type: "Cover Letter")
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(dataManager.coverLetterDocuments) { document in
                            CoverLetterDocumentThumbnailView(document: document)
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    private func deleteCoverLetterDocuments(offsets: IndexSet) {
        for index in offsets {
            dataManager.deleteCoverLetterDocument(dataManager.coverLetterDocuments[index])
        }
    }
}

struct EmptyDocumentsView: View {
    let type: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.on.doc")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No \(type) Documents")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create your first \(type.lowercased()) using one of our templates")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

struct CVDocumentThumbnailView: View {
    let document: CVDocument
    @EnvironmentObject private var dataManager: DataManager
    @State private var showingPDFPreview = false
    @State private var generatedPDFData: Data?
    @State private var thumbnailImage: UIImage?
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        Button(action: {
            generateAndShowPDF()
        }) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                        .aspectRatio(210/297, contentMode: .fit) // A4 aspect ratio
                    
                    if let thumbnailImage = thumbnailImage {
                        Image(uiImage: thumbnailImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else if isGenerating {
                        ProgressView()
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 40))
                                .foregroundColor(Color(hex: document.colorScheme.primaryColor))
                            
                            if let template = dataManager.getCVTemplate(by: document.templateId) {
                                Text(template.name)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Color scheme indicator
                    VStack {
                        HStack {
                            Spacer()
                            Circle()
                                .fill(Color(hex: document.colorScheme.primaryColor))
                                .frame(width: 16, height: 16)
                                .padding(.top, 8)
                                .padding(.trailing, 8)
                        }
                        Spacer()
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(document.fileName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(document.lastModified.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if let application = dataManager.applications.first(where: { $0.id == document.applicationId }) {
                        Text(application.companyName)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(action: exportPDF) {
                Label("Export PDF", systemImage: "square.and.arrow.up")
            }
            
            Button(action: duplicateDocument) {
                Label("Duplicate", systemImage: "doc.on.doc")
            }
            
            Divider()
            
            Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                Label("Delete", systemImage: "trash")
            }
        }
        .onAppear {
            generateThumbnail()
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
        .alert("Delete Document", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteDocument()
            }
        } message: {
            Text("Are you sure you want to delete '\(document.fileName)'? This action cannot be undone.")
        }
    }
    
    private func generateThumbnail() {
        guard thumbnailImage == nil && !isGenerating else { return }
        
        isGenerating = true
        
        Task {
            do {
                let pdfData = try await document.generatePDF()
                
                if let pdfDocument = PDFDocument(data: pdfData),
                   let page = pdfDocument.page(at: 0) {
                    let pageSize = page.bounds(for: .mediaBox)
                    let thumbnailWidth: CGFloat = 200
                    let thumbnailHeight = thumbnailWidth * (pageSize.height / pageSize.width)
                    let renderer = UIGraphicsImageRenderer(size: CGSize(width: thumbnailWidth, height: thumbnailHeight))
                    
                    let image = renderer.image { context in
                        UIColor.white.set()
                        context.fill(CGRect(origin: .zero, size: renderer.format.bounds.size))
                        
                        let cgContext = context.cgContext
                        cgContext.saveGState()
                        
                        // Transform coordinate system for PDF rendering
                        cgContext.translateBy(x: 0, y: thumbnailHeight)
                        cgContext.scaleBy(x: 1, y: -1)
                        
                        // Scale to fit the thumbnail while maintaining aspect ratio
                        let scaleX = thumbnailWidth / pageSize.width
                        let scaleY = thumbnailHeight / pageSize.height
                        let scale = min(scaleX, scaleY)
                        
                        cgContext.scaleBy(x: scale, y: scale)
                        
                        // Center the content if needed
                        let scaledWidth = pageSize.width * scale
                        let scaledHeight = pageSize.height * scale
                        let offsetX = (thumbnailWidth - scaledWidth) / (2 * scale)
                        let offsetY = (thumbnailHeight - scaledHeight) / (2 * scale)
                        cgContext.translateBy(x: offsetX, y: offsetY)
                        
                        // Draw the PDF page
                        page.draw(with: .mediaBox, to: cgContext)
                        
                        cgContext.restoreGState()
                    }
                    
                    await MainActor.run {
                        self.thumbnailImage = image
                        self.isGenerating = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.isGenerating = false
                }
            }
        }
    }
    
    private func generateAndShowPDF() {
        guard !isGenerating else { return }
        
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
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showingError = true
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
    
    private func deleteDocument() {
        dataManager.deleteCVDocument(document)
    }
}

struct CoverLetterDocumentThumbnailView: View {
    let document: CoverLetterDocument
    @EnvironmentObject private var dataManager: DataManager
    @State private var showingPDFPreview = false
    @State private var generatedPDFData: Data?
    @State private var thumbnailImage: UIImage?
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        Button(action: {
            generateAndShowPDF()
        }) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                        .aspectRatio(210/297, contentMode: .fit) // A4 aspect ratio
                    
                    if let thumbnailImage = thumbnailImage {
                        Image(uiImage: thumbnailImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else if isGenerating {
                        ProgressView()
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "doc.plaintext")
                                .font(.system(size: 40))
                                .foregroundColor(Color(hex: document.colorScheme.primaryColor))
                            
                            if let template = dataManager.getCoverLetterTemplate(by: document.templateId) {
                                Text(template.name)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Color scheme indicator
                    VStack {
                        HStack {
                            Spacer()
                            Circle()
                                .fill(Color(hex: document.colorScheme.primaryColor))
                                .frame(width: 16, height: 16)
                                .padding(.top, 8)
                                .padding(.trailing, 8)
                        }
                        Spacer()
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(document.fileName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(document.lastModified.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if let application = dataManager.applications.first(where: { $0.id == document.applicationId }) {
                        Text(application.companyName)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    } else if !document.content.recipientCompany.isEmpty {
                        Text(document.content.recipientCompany)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(action: exportPDF) {
                Label("Export PDF", systemImage: "square.and.arrow.up")
            }
            
            Button(action: duplicateDocument) {
                Label("Duplicate", systemImage: "doc.on.doc")
            }
            
            Divider()
            
            Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                Label("Delete", systemImage: "trash")
            }
        }
        .onAppear {
            generateThumbnail()
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
        .alert("Delete Document", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteDocument()
            }
        } message: {
            Text("Are you sure you want to delete '\(document.fileName)'? This action cannot be undone.")
        }
    }
    
    private func generateThumbnail() {
        guard thumbnailImage == nil && !isGenerating else { return }
        
        isGenerating = true
        
        Task {
            do {
                let pdfData = try await document.generatePDF()
                
                if let pdfDocument = PDFDocument(data: pdfData),
                   let page = pdfDocument.page(at: 0) {
                    let pageSize = page.bounds(for: .mediaBox)
                    let thumbnailWidth: CGFloat = 200
                    let thumbnailHeight = thumbnailWidth * (pageSize.height / pageSize.width)
                    let renderer = UIGraphicsImageRenderer(size: CGSize(width: thumbnailWidth, height: thumbnailHeight))
                    
                    let image = renderer.image { context in
                        UIColor.white.set()
                        context.fill(CGRect(origin: .zero, size: renderer.format.bounds.size))
                        
                        let cgContext = context.cgContext
                        cgContext.saveGState()
                        
                        // Transform coordinate system for PDF rendering
                        cgContext.translateBy(x: 0, y: thumbnailHeight)
                        cgContext.scaleBy(x: 1, y: -1)
                        
                        // Scale to fit the thumbnail while maintaining aspect ratio
                        let scaleX = thumbnailWidth / pageSize.width
                        let scaleY = thumbnailHeight / pageSize.height
                        let scale = min(scaleX, scaleY)
                        
                        cgContext.scaleBy(x: scale, y: scale)
                        
                        // Center the content if needed
                        let scaledWidth = pageSize.width * scale
                        let scaledHeight = pageSize.height * scale
                        let offsetX = (thumbnailWidth - scaledWidth) / (2 * scale)
                        let offsetY = (thumbnailHeight - scaledHeight) / (2 * scale)
                        cgContext.translateBy(x: offsetX, y: offsetY)
                        
                        // Draw the PDF page
                        page.draw(with: .mediaBox, to: cgContext)
                        
                        cgContext.restoreGState()
                    }
                    
                    await MainActor.run {
                        self.thumbnailImage = image
                        self.isGenerating = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.isGenerating = false
                }
            }
        }
    }
    
    private func generateAndShowPDF() {
        guard !isGenerating else { return }
        
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
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showingError = true
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
    
    private func deleteDocument() {
        dataManager.deleteCoverLetterDocument(document)
    }
}

#Preview {
    NavigationStack {
        DocumentsView()
            .environmentObject(DataManager.shared)
    }
}