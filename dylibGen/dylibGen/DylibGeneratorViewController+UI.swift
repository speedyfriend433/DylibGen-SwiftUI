//
//  DylibGeneratorViewController+UI.swift
//  dylibGen
//
//  Created by 지안 on 2025/01/06.
//

import UIKit

extension DylibGeneratorViewController {
    func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Dylib Generator"
        
        // Add template selector
        view.addSubview(templateSelector)
        templateSelector.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            templateSelector.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            templateSelector.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            templateSelector.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        // Add source code text view
        view.addSubview(sourceCodeTextView)
        sourceCodeTextView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sourceCodeTextView.topAnchor.constraint(equalTo: templateSelector.bottomAnchor, constant: 20),
            sourceCodeTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            sourceCodeTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            sourceCodeTextView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.6)
        ])
        
        // Add generate button
        view.addSubview(generateButton)
        generateButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            generateButton.topAnchor.constraint(equalTo: sourceCodeTextView.bottomAnchor, constant: 20),
            generateButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            generateButton.widthAnchor.constraint(equalToConstant: 200),
            generateButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Add actions
        templateSelector.addTarget(self, action: #selector(templateChanged), for: .valueChanged)
        generateButton.addTarget(self, action: #selector(generateTapped), for: .touchUpInside)
    }
    
    @objc private func templateChanged() {
        switch templateSelector.selectedSegmentIndex {
        case 0: // Tweak
            sourceCodeTextView.text = TemplateManager.shared.getTweakTemplate(className: "UIViewController")
        case 1: // Hook
            sourceCodeTextView.text = TemplateManager.shared.getHookTemplate()
        default: // Custom
            sourceCodeTextView.text = "// Enter your custom code here"
        }
    }
    
    @objc private func generateTapped() {
        guard let source = sourceCodeTextView.text, !source.isEmpty else {
            showAlert(title: "Error", message: "Please enter source code")
            return
        }
        
        do {
            let dylibURL = try DylibGenerator.shared.generateDylib(fromSource: source, name: "CustomTweak")
            showSuccess(dylibPath: dylibURL.path)
        } catch {
            showAlert(title: "Error", message: error.localizedDescription)
        }
    }
}
