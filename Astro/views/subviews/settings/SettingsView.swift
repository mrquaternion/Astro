//
//  SettingsView.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-25.
//

import SwiftUI

struct SettingsView: View {
    
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    Section("Account") {
                        NavigationLink("Subscription") {
                            
                        }
                        NavigationLink("Downloads") {
                            
                        }
                    }
                    
                    Section("About") {
                        NavigationLink("Privacy Policy") {
                        }
                        NavigationLink("Terms of Service") {
                        }
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.0.0")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .navigationTitle("Settings")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            isPresented = false
                        } label: {
                            Image(systemName: "xmark")
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView(isPresented: .constant(true))
}
