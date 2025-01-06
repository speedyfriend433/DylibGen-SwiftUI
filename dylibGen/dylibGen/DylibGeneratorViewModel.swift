//
//  DylibGeneratorViewModel.swift
//  dylibGen
//
//  Created by 지안 on 2025/01/06.
//

import SwiftUI
import Foundation

class DylibGeneratorViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var sourceCode: String = ""
    @Published var selectedTemplate: TemplateType = .tweak
    @Published var dylibName: String = "CustomTweak"
    @Published var isGenerating: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var generatedDylibURL: URL?
    @Published var compilationProgress: Double = 0
    @Published var compilationStep: String = ""
    
    // MARK: - Private Properties
    private let generator = DylibGenerator()
    private let templateManager = TemplateManager.shared
    
    // MARK: - Initialization
    init() {
        loadTemplate()
    }
    
    // MARK: - Public Methods
    func templateChanged() {
        loadTemplate()
    }
    
    func generateDylib() async throws {
        guard !sourceCode.isEmpty else {
            throw DylibGenerator.MakeError.compilationFailed
        }
        
        DispatchQueue.main.async {
            self.isGenerating = true
            self.compilationProgress = 0
            self.compilationStep = "Starting compilation..."
        }
        
        do {
            let url = try await generator.generateDylib(
                fromSource: sourceCode,
                name: dylibName
            )
            
            DispatchQueue.main.async {
                self.generatedDylibURL = url
                self.isGenerating = false
                self.compilationProgress = 1.0
                self.compilationStep = "Compilation complete"
            }
        } catch {
            DispatchQueue.main.async {
                self.isGenerating = false
                self.showError = true
                self.errorMessage = "Generation failed: \(error.localizedDescription)"
                self.compilationProgress = 0
                self.compilationStep = "Compilation failed"
            }
        }
    }
    
    func reset() {
        sourceCode = ""
        dylibName = "CustomTweak"
        compilationProgress = 0
        compilationStep = ""
        generatedDylibURL = nil
        isGenerating = false
        showError = false
        errorMessage = ""
        loadTemplate()
    }
    
    // MARK: - Private Methods
    private func loadTemplate() {
        sourceCode = templateManager.getTemplate(for: selectedTemplate)
    }
}

// MARK: - Template Type Enum
enum TemplateType: String, CaseIterable, Identifiable {
    case tweak = "Tweak"
    case hook = "Hook"
    case custom = "Custom"
    
    var id: String { rawValue }
}

// MARK: - Template Manager
class TemplateManager {
    static let shared = TemplateManager()
    
    func getTemplate(for type: TemplateType) -> String {
        switch type {
        case .tweak:
            return """
            #import <Foundation/Foundation.h>
            #import <UIKit/UIKit.h>
            
            %hook UIViewController
            
            -(void)viewDidLoad {
                %orig;
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Hooked!"
                                                                             message:@"This view controller has been hooked"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                        style:UIAlertActionStyleDefault
                                                      handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
            }
            
            %end
            """
            
        case .hook:
            return """
            #import <Foundation/Foundation.h>
            
            %hook NSURLConnection
            
            + (void)sendAsynchronousRequest:(NSURLRequest *)request
                                    queue:(NSOperationQueue *)queue
                        completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler {
                // Modify request or response here
                %orig(request, queue, handler);
            }
            
            %end
            """
            
        case .custom:
            return "// Enter your custom code here"
        }
    }
}

// MARK: - Validation Extension
extension DylibGeneratorViewModel {
    var isValidInput: Bool {
        !sourceCode.isEmpty && !dylibName.isEmpty
    }
    
    var formattedProgress: String {
        String(format: "%.0f%%", compilationProgress * 100)
    }
}
