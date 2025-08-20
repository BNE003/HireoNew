//
//  DocumentsView.swift
//  Hireo
//
//  Created by Benedikt Held on 19.08.25.
//

import SwiftUI

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
    
    var body: some View {
        Group {
            if dataManager.cvDocuments.isEmpty {
                EmptyDocumentsView(type: "CV")
            } else {
                List {
                    ForEach(dataManager.cvDocuments) { document in
                        CVDocumentRowView(document: document)
                    }
                    .onDelete(perform: deleteCVDocuments)
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
    
    var body: some View {
        Group {
            if dataManager.coverLetterDocuments.isEmpty {
                EmptyDocumentsView(type: "Cover Letter")
            } else {
                List {
                    ForEach(dataManager.coverLetterDocuments) { document in
                        CoverLetterDocumentRowView(document: document)
                    }
                    .onDelete(perform: deleteCoverLetterDocuments)
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

struct CVDocumentRowView: View {
    let document: CVDocument
    @EnvironmentObject private var dataManager: DataManager
    @State private var showingDocumentDetail = false
    @State private var showingPDFPreview = false
    @State private var generatedPDFData: Data?
    @State private var isExporting = false
    @State private var errorMessage: String?
    @State private var showingError = false
    
    var body: some View {
        Button(action: {
            showingDocumentDetail = true
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(document.fileName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        if let template = dataManager.getCVTemplate(by: document.templateId) {
                            Text(template.name)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Color scheme indicator
                        Circle()
                            .fill(Color(hex: document.colorScheme.primaryColor))
                            .frame(width: 12, height: 12)
                    }
                    
                    HStack {
                        Text(document.lastModified.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let application = dataManager.applications.first(where: { $0.id == document.applicationId }) {
                            Spacer()
                            Text("• \(application.companyName)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    Button(action: exportPDF) {
                        HStack(spacing: 4) {
                            if isExporting {
                                ProgressView()
                                    .scaleEffect(0.6)
                            } else {
                                Image(systemName: "square.and.arrow.up")
                            }
                        }
                        .foregroundColor(.blue)
                        .padding(8)
                    }
                    .buttonStyle(.plain)
                    .disabled(isExporting)
                    
                    Button(action: previewPDF) {
                        Image(systemName: "eye")
                            .foregroundColor(.green)
                            .padding(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingDocumentDetail) {
            CVDocumentDetailView(document: document)
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
    
    private func exportPDF() {
        isExporting = true
        
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
                    
                    self.isExporting = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showingError = true
                    self.isExporting = false
                }
            }
        }
    }
    
    private func previewPDF() {
        Task {
            do {
                let pdfData = try await document.generatePDF()
                
                await MainActor.run {
                    self.generatedPDFData = pdfData
                    self.showingPDFPreview = true
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showingError = true
                }
            }
        }
    }
}

struct CoverLetterDocumentRowView: View {
    let document: CoverLetterDocument
    @EnvironmentObject private var dataManager: DataManager
    @State private var showingDocumentDetail = false
    @State private var showingPDFPreview = false
    @State private var generatedPDFData: Data?
    @State private var isExporting = false
    @State private var errorMessage: String?
    @State private var showingError = false
    
    var body: some View {
        Button(action: {
            showingDocumentDetail = true
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(document.fileName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        if let template = dataManager.getCoverLetterTemplate(by: document.templateId) {
                            Text(template.name)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Color scheme indicator
                        Circle()
                            .fill(Color(hex: document.colorScheme.primaryColor))
                            .frame(width: 12, height: 12)
                    }
                    
                    HStack {
                        Text(document.lastModified.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let application = dataManager.applications.first(where: { $0.id == document.applicationId }) {
                            Spacer()
                            Text("• \(application.companyName)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        } else if !document.content.recipientCompany.isEmpty {
                            Spacer()
                            Text("• \(document.content.recipientCompany)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    Button(action: exportPDF) {
                        HStack(spacing: 4) {
                            if isExporting {
                                ProgressView()
                                    .scaleEffect(0.6)
                            } else {
                                Image(systemName: "square.and.arrow.up")
                            }
                        }
                        .foregroundColor(.blue)
                        .padding(8)
                    }
                    .buttonStyle(.plain)
                    .disabled(isExporting)
                    
                    Button(action: previewPDF) {
                        Image(systemName: "eye")
                            .foregroundColor(.green)
                            .padding(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingDocumentDetail) {
            CoverLetterDocumentDetailView(document: document)
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
    
    private func exportPDF() {
        isExporting = true
        
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
                    
                    self.isExporting = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showingError = true
                    self.isExporting = false
                }
            }
        }
    }
    
    private func previewPDF() {
        Task {
            do {
                let pdfData = try await document.generatePDF()
                
                await MainActor.run {
                    self.generatedPDFData = pdfData
                    self.showingPDFPreview = true
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showingError = true
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        DocumentsView()
            .environmentObject(DataManager.shared)
    }
}