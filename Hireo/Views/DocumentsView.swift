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
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(document.fileName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let template = dataManager.getCVTemplate(by: document.templateId) {
                    Text(template.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text(document.lastModified, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                // TODO: Export PDF
            }) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.blue)
                    .padding(8)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

struct CoverLetterDocumentRowView: View {
    let document: CoverLetterDocument
    @EnvironmentObject private var dataManager: DataManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(document.fileName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let template = dataManager.getCoverLetterTemplate(by: document.templateId) {
                    Text(template.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text(document.lastModified, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                // TODO: Export PDF
            }) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.blue)
                    .padding(8)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        DocumentsView()
            .environmentObject(DataManager.shared)
    }
}