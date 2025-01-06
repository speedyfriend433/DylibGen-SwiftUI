//
//  CodeEditorView.swift
//  dylibGen
//
//  Created by 지안 on 2025/01/06.
//

import SwiftUI

struct CodeEditorView: View {
    @Binding var text: String
    @State private var height: CGFloat = 200
    
    var body: some View {
        ScrollView {
            TextEditor(text: $text)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: height)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
        }
        .padding(.horizontal)
    }
}
