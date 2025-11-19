# TalkGPT - Cloud LLM Backend Integration

## Overview

TalkGPT now supports cloud-based LLM backends, enabling powerful AI capabilities without requiring on-device model files. This update adds support for:

- **OpenAI** (GPT-4o, GPT-4 Turbo, GPT-3.5 Turbo)
- **Anthropic** (Claude Sonnet 4.5, Claude 3.5 Sonnet, Claude 3 Opus)
- **Custom** (Any OpenAI-compatible API)

## Quick Start

### 1. Set API Keys (Environment Variables - Recommended)

The easiest way to configure TalkGPT is via environment variables:

```bash
# OpenAI
export OPENAI_API_KEY="sk-..."

# Anthropic
export ANTHROPIC_API_KEY="sk-ant-..."

# Custom OpenAI-compatible endpoint (optional)
export OPENAI_BASE_URL="https://your-custom-endpoint.com/v1"
```

### 2. Or Configure in App

1. Open TalkGPT
2. Go to **Settings** tab
3. Tap **Configure Backend**
4. Select your backend (OpenAI or Anthropic)
5. Enter your API key
6. Select a model
7. Tap **Test Connection** to verify
8. Tap **Save**

### 3. Start Chatting

Once configured, the Chat tab will use your selected backend automatically!

## Supported Backends

### OpenAI

**Models:**
- `gpt-4o` - Latest multimodal model (128K context) ⭐ Recommended
- `gpt-4-turbo` - Fast and capable (128K context)
- `gpt-3.5-turbo` - Cost-effective (16K context)

**Get API Key:**
- Visit: https://platform.openai.com/api-keys
- Cost: Pay-per-token (see OpenAI pricing)

**Context Length:** Up to 128,000 tokens (gpt-4o)

### Anthropic (Claude)

**Models:**
- `claude-sonnet-4.5-20250929` - Latest and most capable ⭐ Recommended
- `claude-3-5-sonnet-20241022` - Excellent reasoning
- `claude-3-opus-20240229` - Most capable Claude 3
- `claude-3-haiku-20240307` - Fastest

**Get API Key:**
- Visit: https://console.anthropic.com/
- Cost: Pay-per-token (see Anthropic pricing)

**Context Length:** Up to 200,000 tokens

### Custom (OpenAI-Compatible)

Any API that follows the OpenAI chat completions format works:

- **Azure OpenAI**: Set base URL to your Azure endpoint
- **LocalAI**: Point to your local instance
- **Other providers**: Any OpenAI-compatible API

## Configuration Methods

### Method 1: Environment Variables (Recommended)

Best for development and security. API keys are never stored in the app.

**macOS/Linux:**
```bash
export OPENAI_API_KEY="sk-..."
export ANTHROPIC_API_KEY="sk-ant-..."
```

**Run app with environment:**
```bash
# If running via Xcode
# Edit scheme → Run → Arguments → Environment Variables
# Add: OPENAI_API_KEY = sk-...
```

### Method 2: In-App Configuration

Convenient for testing. API keys are stored in UserDefaults (not encrypted).

1. Settings → Configure Backend
2. Enter API key
3. Save

**Note**: Environment variables take precedence over in-app configuration.

## Architecture

### Backend Abstraction

```swift
protocol LLMBackend {
    var name: String { get }
    var isConfigured: Bool { get }
    var supportedModels: [String] { get }

    func configure(apiKey: String, baseURL: String?) throws
    func generateStream(prompt: String, model: String, parameters: ModelParameters)
        -> AsyncThrowingStream<String, Error>
}
```

### Adding New Backends

To add a new OpenAI-compatible backend:

1. Create new backend class conforming to `LLMBackend`
2. Implement streaming chat completions
3. Add to `BackendType` enum in `LLMConfiguration`
4. Update UI to show new option

**Example: Custom Provider**

```swift
class CustomBackend: LLMBackend {
    let name = "Custom Provider"
    private var apiKey: String = ""
    private var baseURL: String = "https://api.custom.com/v1"

    var isConfigured: Bool { !apiKey.isEmpty }
    var supportedModels: [String] { ["custom-model-1", "custom-model-2"] }

    func configure(apiKey: String, baseURL: String?) throws {
        self.apiKey = apiKey
        if let baseURL = baseURL { self.baseURL = baseURL }
    }

    func generateStream(prompt: String, model: String, parameters: ModelParameters)
        -> AsyncThrowingStream<String, Error> {
        // Implement streaming using URLSession
        // Follow OpenAI chat completions format
    }
}
```

## API Compatibility

### OpenAI Chat Completions Format

TalkGPT uses the standard OpenAI chat completions API with streaming:

**Request:**
```json
{
  "model": "gpt-4o",
  "messages": [{"role": "user", "content": "Hello!"}],
  "temperature": 0.7,
  "max_tokens": 2048,
  "top_p": 0.9,
  "stream": true
}
```

**Streaming Response:**
```
data: {"choices":[{"delta":{"content":"Hello"}}]}
data: {"choices":[{"delta":{"content":"!"}}]}
data: [DONE]
```

### Anthropic Messages API

For Claude models, we use the Anthropic Messages API:

**Request:**
```json
{
  "model": "claude-sonnet-4.5-20250929",
  "messages": [{"role": "user", "content": "Hello!"}],
  "max_tokens": 2048,
  "temperature": 0.7,
  "stream": true
}
```

**Streaming Response:**
```
data: {"type":"content_block_delta","delta":{"text":"Hello"}}
data: {"type":"message_stop"}
```

## Features

### ✅ Implemented

- [x] OpenAI GPT-4o, GPT-4 Turbo, GPT-3.5 Turbo
- [x] Anthropic Claude Sonnet 4.5, 3.5 Sonnet, 3 Opus
- [x] Streaming responses with real-time display
- [x] Environment variable configuration
- [x] In-app backend configuration UI
- [x] Model selection per backend
- [x] Connection testing
- [x] Parameter configuration (temperature, max tokens, etc.)
- [x] Custom OpenAI-compatible endpoints

### Document Q&A

When you select documents in TalkGPT, their OCR-extracted text is automatically included in the prompt:

```
System: You are a helpful AI assistant...

DOCUMENT_CONTEXT:
--- Document 1: example.pdf ---
Page 1:
[OCR extracted text from document]