//
//  TemplateType.swift
//  dylibGen
//
//  Created by 지안 on 2025/01/06.
//

import Foundation

enum TemplateType: String, CaseIterable, Identifiable {
    case tweak = "Tweak"
    case hook = "Hook"
    case custom = "Custom"
    
    var id: String { rawValue }
}
