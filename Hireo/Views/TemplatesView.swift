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
    
    var body: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(height: 120)
                .overlay(
                    VStack {
                        Image(systemName: "doc.text")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        Text("Preview")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                )
            
            VStack(spacing: 4) {
                Text(template.name)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                
                Text(template.category.localizedString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Button("Use Template") {
                // TODO: Navigate to CV creation
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding()
        .cardStyle()
    }
}

struct CoverLetterTemplateCard: View {
    let template: CoverLetterTemplate
    
    var body: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(height: 120)
                .overlay(
                    VStack {
                        Image(systemName: "doc.text")
                            .font(.system(size: 40))
                            .foregroundColor(.green)
                        Text("Preview")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                )
            
            VStack(spacing: 4) {
                Text(template.name)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                
                Text(template.category.localizedString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Button("Use Template") {
                // TODO: Navigate to cover letter creation
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding()
        .cardStyle()
    }
}

#Preview {
    NavigationStack {
        TemplatesView()
            .environmentObject(DataManager.shared)
    }
}