//
//  ModelSettingsSheet.swift
//  TalkGPT
//
//  Created by TalkGPT on 2025-11-19.
//  Phase 2 Implementation
//

import SwiftUI

struct ModelSettingsSheet: View {
    @ObservedObject var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var tempParameters: ModelParameters

    init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
        _tempParameters = State(initialValue: viewModel.modelParameters)
    }

    var body: some View {
        NavigationView {
            Form {
                // Model Info Section
                Section {
                    HStack {
                        Text("Model")
                        Spacer()
                        Text(viewModel.modelInfo.name)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Status")
                        Spacer()
                        Text(viewModel.isModelLoaded ? "Loaded" : "Not Loaded")
                            .foregroundColor(viewModel.isModelLoaded ? .green : .red)
                    }

                    if viewModel.isModelLoaded {
                        HStack {
                            Text("Size")
                            Spacer()
                            Text(viewModel.modelInfo.size)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("Context Length")
                            Spacer()
                            Text("\(viewModel.modelInfo.contextLength)")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Model Information")
                } footer: {
                    if !viewModel.isModelLoaded {
                        Text("No model is currently loaded. In production, you would load a GGUF model file here.")
                    }
                }

                // Generation Parameters Section
                Section {
                    VStack(spacing: 12) {
                        HStack {
                            Text("Temperature")
                            Spacer()
                            Text(String(format: "%.2f", tempParameters.temperature))
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $tempParameters.temperature, in: 0.0...2.0, step: 0.05)
                    }

                    VStack(spacing: 12) {
                        HStack {
                            Text("Max Tokens")
                            Spacer()
                            Text("\(tempParameters.maxTokens)")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: Binding(
                            get: { Double(tempParameters.maxTokens) },
                            set: { tempParameters.maxTokens = Int($0) }
                        ), in: 128...4096, step: 128)
                    }

                    VStack(spacing: 12) {
                        HStack {
                            Text("Top P")
                            Spacer()
                            Text(String(format: "%.2f", tempParameters.topP))
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $tempParameters.topP, in: 0.0...1.0, step: 0.05)
                    }

                    VStack(spacing: 12) {
                        HStack {
                            Text("Top K")
                            Spacer()
                            Text("\(tempParameters.topK)")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: Binding(
                            get: { Double(tempParameters.topK) },
                            set: { tempParameters.topK = Int($0) }
                        ), in: 1...100, step: 1)
                    }
                } header: {
                    Text("Generation Parameters")
                } footer: {
                    Text("Temperature controls randomness. Higher = more creative, Lower = more focused.")
                }

                // Presets Section
                Section {
                    Button("Precise (Temp: 0.3)") {
                        tempParameters = .precise
                    }

                    Button("Balanced (Temp: 0.7)") {
                        tempParameters = .default
                    }

                    Button("Creative (Temp: 0.9)") {
                        tempParameters = .creative
                    }
                } header: {
                    Text("Presets")
                }
            }
            .navigationTitle("Model Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.updateParameters(tempParameters)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ModelSettingsSheet_Previews: PreviewProvider {
    static var previews: some View {
        ModelSettingsSheet(viewModel: ChatViewModel())
    }
}
