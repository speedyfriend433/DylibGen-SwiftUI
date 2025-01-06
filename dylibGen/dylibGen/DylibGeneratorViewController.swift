//
//  DylibGeneratorViewController.swift
//  dylibGen
//
//  Created by 지안 on 2025/01/06.
//

import SwiftUI

struct DylibGeneratorView: View {
    @StateObject private var viewModel = DylibGeneratorViewModel()
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Template Selector
                Picker("Template", selection: $viewModel.selectedTemplate) {
                    ForEach(TemplateType.allCases) { template in
                        Text(template.rawValue).tag(template)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .onChange(of: viewModel.selectedTemplate) { _ in
                    viewModel.templateChanged()
                }
                
                // Dylib Name Input
                TextField("Dylib Name", text: $viewModel.dylibName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                
                // Source Code Editor
                TextEditor(text: $viewModel.sourceCode)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxHeight: .infinity)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    .padding()
                
                // Progress View
                if viewModel.isGenerating {
                    VStack(spacing: 10) {
                        ProgressView(value: viewModel.compilationProgress, total: 1.0)
                        Text("\(viewModel.compilationStep) - \(viewModel.formattedProgress)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                
                // Generate Button
                Button {
                    Task {
                        try await viewModel.generateDylib()
                        showingShareSheet = true
                    }
                } label: {
                    if viewModel.isGenerating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Generate Dylib")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isGenerating || !viewModel.isValidInput)
                .padding()
            }
            .navigationTitle("Dylib Generator")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.reset() }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = viewModel.generatedDylibURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
    }
    
    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) {}
}

struct DylibGeneratorView_Previews: PreviewProvider {
    static var previews: some View {
        DylibGeneratorView()
    }
}
