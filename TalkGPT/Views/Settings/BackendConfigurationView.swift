//
//  BackendConfigurationView.swift
//  TalkGPT
//
//  Created by TalkGPT on 2025-11-19.
//  Cloud Backend Configuration
//

import SwiftUI

struct BackendConfigurationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var configuration: LLMConfiguration
    @State private var showSuccessAlert = false
    @State private var testingConnection = false
    @State private var testResult: String?

    private let llmManager = LLMManager.shared

    init() {
        _configuration = State(initialValue: LLMManager.shared.getConfiguration())
    }

    var body: some View {
        NavigationView {
            Form {
                // Backend Selection
                Section {
                    Picker("Backend", selection: $configuration.selectedBackend) {
                        ForEach(LLMConfiguration.BackendType.allCases, id: \.self) { backend in
                            Text(backend.displayName).tag(backend)
                        }
                    }
                } header: {
                    Text("LLM Backend")
                } footer: {
                    Text("Select your preferred AI backend provider")
                }

                // OpenAI Configuration
                if configuration.selectedBackend == .openAI || configuration.selectedBackend == .custom {
                    Section {
                        SecureField("API Key", text: $configuration.openAIAPIKey)
                            .textContentType(.password)
                            .autocapitalization(.none)

                        if configuration.selectedBackend == .custom {
                            TextField("Base URL", text: Binding(
                                get: { configuration.openAIBaseURL ?? "" },
                                set: { configuration.openAIBaseURL = $0.isEmpty ? nil : $0 }
                            ))
                            .textContentType(.URL)
                            .autocapitalization(.none)
                            .keyboardType(.URL)
                        }
                    } header: {
                        Text("OpenAI Configuration")
                    } footer: {
                        VStack(alignment: .leading, spacing: 8) {
                            if configuration.openAIAPIKey.isEmpty {
                                Text("Enter your OpenAI API key or set OPENAI_API_KEY environment variable")
                            } else {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("API key configured")
                                }
                            }

                            if configuration.selectedBackend == .custom {
                                Text("For OpenAI-compatible APIs (e.g., Azure OpenAI, LocalAI)")
                            }
                        }
                    }
                }

                // Anthropic Configuration
                if configuration.selectedBackend == .anthropic {
                    Section {
                        SecureField("API Key", text: $configuration.anthropicAPIKey)
                            .textContentType(.password)
                            .autocapitalization(.none)
                    } header: {
                        Text("Anthropic Configuration")
                    } footer: {
                        if configuration.anthropicAPIKey.isEmpty {
                            Text("Enter your Anthropic API key or set ANTHROPIC_API_KEY environment variable")
                        } else {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("API key configured")
                            }
                        }
                    }
                }

                // Model Selection
                Section {
                    Picker("Model", selection: $configuration.selectedModel) {
                        ForEach(modelOptions, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                } header: {
                    Text("Model Selection")
                } footer: {
                    Text(modelDescription)
                }

                // Environment Variables Info
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("You can set API keys via environment variables:")
                            .font(.subheadline)

                        Text("• OPENAI_API_KEY")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("• ANTHROPIC_API_KEY")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("• OPENAI_BASE_URL (optional)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Environment Variables")
                }

                // Actions
                Section {
                    Button(action: testConnection) {
                        HStack {
                            if testingConnection {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(testingConnection ? "Testing..." : "Test Connection")
                        }
                    }
                    .disabled(!isConfigValid || testingConnection)

                    if let result = testResult {
                        HStack {
                            Image(systemName: result.contains("Success") ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(result.contains("Success") ? .green : .red)
                            Text(result)
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("Backend Configuration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveConfiguration()
                    }
                    .disabled(!isConfigValid)
                }
            }
            .alert("Configuration Saved", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your backend configuration has been saved successfully.")
            }
        }
    }

    // MARK: - Computed Properties

    private var isConfigValid: Bool {
        switch configuration.selectedBackend {
        case .openAI, .custom:
            return !configuration.openAIAPIKey.isEmpty
        case .anthropic:
            return !configuration.anthropicAPIKey.isEmpty
        }
    }

    private var modelOptions: [String] {
        return configuration.selectedBackend.defaultModels
    }

    private var modelDescription: String {
        switch configuration.selectedModel {
        case let model where model.contains("gpt-4o"):
            return "GPT-4o - Latest multimodal model with vision (128K context)"
        case let model where model.contains("gpt-4-turbo"):
            return "GPT-4 Turbo - Faster and more capable (128K context)"
        case let model where model.contains("gpt-3.5"):
            return "GPT-3.5 Turbo - Fast and cost-effective (16K context)"
        case let model where model.contains("claude-sonnet-4.5"):
            return "Claude Sonnet 4.5 - Latest and most capable (200K context)"
        case let model where model.contains("claude-3-5-sonnet"):
            return "Claude 3.5 Sonnet - Excellent reasoning (200K context)"
        case let model where model.contains("claude-3-opus"):
            return "Claude 3 Opus - Most capable Claude 3 (200K context)"
        case let model where model.contains("claude-3-haiku"):
            return "Claude 3 Haiku - Fastest Claude model (200K context)"
        default:
            return "Selected model"
        }
    }

    // MARK: - Actions

    private func saveConfiguration() {
        llmManager.updateConfiguration(configuration)
        showSuccessAlert = true
    }

    private func testConnection() {
        testingConnection = true
        testResult = nil

        Task {
            do {
                // Create a temporary backend to test
                let testBackend: LLMBackend

                switch configuration.selectedBackend {
                case .openAI, .custom:
                    testBackend = OpenAIBackend()
                    try testBackend.configure(
                        apiKey: configuration.openAIAPIKey,
                        baseURL: configuration.openAIBaseURL
                    )

                case .anthropic:
                    testBackend = AnthropicBackend()
                    try testBackend.configure(
                        apiKey: configuration.anthropicAPIKey,
                        baseURL: nil
                    )
                }

                // Try a simple generation to test
                let stream = testBackend.generateStream(
                    prompt: "Say 'hello' if you can read this.",
                    model: configuration.selectedModel,
                    parameters: .default
                )

                var receivedResponse = false
                for try await _ in stream {
                    receivedResponse = true
                    break // Just need to verify we got a response
                }

                if receivedResponse {
                    await MainActor.run {
                        testResult = "✓ Success: Connection established"
                        testingConnection = false
                    }
                } else {
                    await MainActor.run {
                        testResult = "✗ Failed: No response received"
                        testingConnection = false
                    }
                }
            } catch {
                await MainActor.run {
                    testResult = "✗ Error: \(error.localizedDescription)"
                    testingConnection = false
                }
            }
        }
    }
}

struct BackendConfigurationView_Previews: PreviewProvider {
    static var previews: some View {
        BackendConfigurationView()
    }
}
