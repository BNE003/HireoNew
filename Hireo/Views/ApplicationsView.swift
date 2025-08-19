//
//  ApplicationsView.swift
//  Hireo
//
//  Created by Benedikt Held on 19.08.25.
//

import SwiftUI

struct ApplicationsView: View {
    @EnvironmentObject private var dataManager: DataManager
    @State private var showingNewApplication = false
    
    var body: some View {
        NavigationStack {
            Group {
                if dataManager.applications.isEmpty {
                    EmptyApplicationsView()
                } else {
                    List {
                        ForEach(dataManager.applications) { application in
                            ApplicationRowView(application: application)
                        }
                        .onDelete(perform: deleteApplications)
                    }
                }
            }
            .navigationTitle("Applications")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingNewApplication = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewApplication) {
            NewApplicationView()
        }
    }
    
    private func deleteApplications(offsets: IndexSet) {
        for index in offsets {
            dataManager.deleteApplication(dataManager.applications[index])
        }
    }
}

struct EmptyApplicationsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Applications Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start by creating your first job application to keep track of your opportunities")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

struct ApplicationRowView: View {
    let application: Application
    
    var body: some View {
        Button(action: {
            // TODO: Navigate to application details
        }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(application.position)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    StatusBadge(status: application.status)
                }
                
                Text(application.companyName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(application.applicationDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

struct StatusBadge: View {
    let status: ApplicationStatus
    
    var body: some View {
        Text(status.localizedString)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(8)
    }
    
    private var statusColor: Color {
        switch status {
        case .draft: return .gray
        case .sent: return .blue
        case .interview: return .orange
        case .rejected: return .red
        case .accepted: return .green
        case .withdrawn: return .purple
        }
    }
}

#Preview {
    NavigationStack {
        ApplicationsView()
            .environmentObject(DataManager.shared)
    }
}