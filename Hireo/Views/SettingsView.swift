//
//  SettingsView.swift
//  Hireo
//
//  Created by Benedikt Held on 19.08.25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var dataManager: DataManager
    @State private var selectedLanguage = "en"
    @State private var enableNotifications = true
    @State private var showingResetAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    Button(action: {
                        // TODO: Navigate to profile edit
                    }) {
                        HStack {
                            Image(systemName: "person.circle")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            Text("Edit Profile")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .buttonStyle(.plain)
                }
                
                Section("Preferences") {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        Text("Language")
                        
                        Spacer()
                        
                        Picker("Language", selection: $selectedLanguage) {
                            Text("English").tag("en")
                            Text("Deutsch").tag("de")
                        }
                        .pickerStyle(.menu)
                    }
                    
                    HStack {
                        Image(systemName: "bell")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        Text("Notifications")
                        
                        Spacer()
                        
                        Toggle("", isOn: $enableNotifications)
                    }
                }
                
                Section("Data") {
                    HStack {
                        Image(systemName: "icloud")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        Text("iCloud Sync")
                        
                        Spacer()
                        
                        Text("Coming Soon")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        Text("Export Data")
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    
                    Button(action: {
                        showingResetAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .frame(width: 24)
                            
                            Text("Reset All Data")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Section("Support") {
                    HStack {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        Text("Help & FAQ")
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    
                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        Text("Contact Support")
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("1")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .alert("Reset All Data", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                // TODO: Implement data reset
            }
        } message: {
            Text("This action cannot be undone. All your profile data, applications, and documents will be permanently deleted.")
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(DataManager.shared)
    }
}