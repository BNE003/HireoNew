//
//  NewApplicationView.swift
//  Hireo
//
//  Created by Benedikt Held on 19.08.25.
//

import SwiftUI

struct NewApplicationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataManager: DataManager
    @State private var companyName = ""
    @State private var position = ""
    @State private var jobDescription = ""
    @State private var applicationDate = Date()
    @State private var contactName = ""
    @State private var contactEmail = ""
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Job Information") {
                    TextField("Company Name", text: $companyName)
                    TextField("Position", text: $position)
                    DatePicker("Application Date", selection: $applicationDate, displayedComponents: .date)
                }
                
                Section("Job Description") {
                    TextField("Job Description", text: $jobDescription, axis: .vertical)
                        .lineLimit(5...10)
                }
                
                Section("Contact Person") {
                    TextField("Contact Name", text: $contactName)
                    TextField("Contact Email", text: $contactEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                Section("Notes") {
                    TextField("Additional notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .navigationTitle("New Application")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        createApplication()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
    
    private var canSave: Bool {
        !companyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !position.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func createApplication() {
        var application = Application(companyName: companyName, position: position)
        application.applicationDate = applicationDate
        application.jobDescription = jobDescription
        application.notes = notes
        
        if !contactName.isEmpty || !contactEmail.isEmpty {
            var contactPerson = ContactPerson()
            contactPerson.name = contactName
            contactPerson.email = contactEmail.isEmpty ? nil : contactEmail
            application.contactPerson = contactPerson
        }
        
        dataManager.saveApplication(application)
        dismiss()
    }
}

#Preview {
    NewApplicationView()
        .environmentObject(DataManager.shared)
}