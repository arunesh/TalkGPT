# TalkGPT - Phase 2: LLM Integration & Chat

## What's New in Phase 2

Phase 2 adds complete LLM-powered chat functionality with document Q&A capabilities to TalkGPT.

### ✅ New Features

1. **Full Chat Interface**
   - Send messages and receive AI responses
   - Streaming text generation for real-time feedback
   - Chat with multiple documents simultaneously
   - Conversation history and management

2. **Document Q&A**
   - Select documents to provide context
   - Ask questions about document content
   - Get answers based on OCR-extracted text
   - Document references in responses

3. **LLM Integration**
   - Protocol-based architecture (ready for llama.cpp)
   - Streaming response generation
   - Configurable model parameters
   - Demonstration mode (works without actual model)

4. **Conversation Management**
   - Create multiple conversations
   - Auto-generated conversation titles
   - Save and load conversations
   - Delete conversations

5. **Model Settings**
   - Adjust temperature, top-p, top-k
   - Preset configurations (Precise, Balanced, Creative)
   - Max tokens and context size
   - Real-time parameter updates

## How to Use

### Starting a Chat

1. **Open the Chat Tab**
   - Tap the Chat tab in the bottom navigation

2. **Select Documents (Optional)**
   - Tap the menu icon (•••) → "Select Documents"
   - Choose one or more documents to chat about
   - Selected documents appear as chips at the top

3. **Send a Message**
   - Type your question in the input field
   - Press the send button (↑)
   - Watch the AI response stream in real-time

### Asking About Documents

**Example Conversations:**

1. **General Question:**
   ```
   You: What is this document about?
   AI: Based on the provided document, it discusses...
   ```

2. **Specific Information:**
   ```
   You: What does page 3 say about the conclusion?
   AI: On page 3, the document concludes that...
   ```

3. **Comparison:**
   ```
   You: (with 2 documents selected) How do these documents differ?
   AI: Comparing the two documents, the first focuses on...
   ```

### Managing Conversations

- **New Conversation**: Tap list icon → "New"
- **Switch Conversations**: Tap list icon → Select conversation
- **Delete Conversation**: Swipe left in conversation list
- **Clear Current**: Menu (•••) → "Clear Conversation"

### Adjusting Model Settings

1. Tap menu (•••) → "Model Settings"
2. Adjust parameters:
   - **Temperature**: 0.0 = focused, 2.0 = creative
   - **Max Tokens**: Response length limit
   - **Top P**: Nucleus sampling threshold
   - **Top K**: Top-k sampling value
3. Or choose a preset: Precise, Balanced, Creative
4. Tap "Save"

## Current Implementation Status

### Demonstration Mode

**Important**: Phase 2 currently runs in **demonstration mode**. This means:

✅ **Working:**
- Complete UI and UX
- Message sending and receiving
- Streaming responses (simulated)
- Document selection
- Conversation management
- All settings and configurations

⚠️ **Simulated:**
- LLM responses (pre-programmed demonstration text)
- Model loading (simulated with delay)
- Token generation (simulated streaming)

### Production Deployment

To use with a real LLM in production:

1. **Add LLM Backend**:
   - Integrate llama.cpp Swift bindings, OR
   - Integrate MLC LLM iOS framework

2. **Implement LLMManager**:
   - Replace simulated generation in `LLMManager.swift`
   - Add actual model loading logic
   - Implement real token generation

3. **Add Model Files**:
   - Download GGUF model (Gemma 2B or Phi-3 Mini)
   - Place in app bundle or documents directory
   - Update model loading UI

**Recommended Models:**
- **Gemma 2B (4-bit)**: ~1.2GB, good balance
- **Phi-3 Mini (4-bit)**: ~2GB, better quality
- **TinyLlama 1.1B**: ~600MB, faster but less capable

## Architecture Overview

### Data Flow

```
User Input
    ↓
ChatViewModel
    ↓
LLMService (builds prompt)
    ↓
    ├─ Document Context (from selected docs)
    ├─ Conversation History (last 5 messages)
    └─ System Prompt
    ↓
LLMManager (generates response)
    ↓
Streaming Tokens → ChatView (real-time display)
    ↓
ConversationService (saves message)
```

### Prompt Engineering

**System Prompt:**
```
You are a helpful AI assistant specialized in answering
questions about documents. You have access to text extracted
from documents via OCR...
```

**Document Context:**
```
DOCUMENT_CONTEXT:
--- Document 1: filename.pdf ---
Page 1:
[OCR extracted text...]

Page 2:
[OCR extracted text...]
```

**Conversation History:**
```
CONVERSATION_HISTORY:
Human: Previous question
Assistant: Previous answer
```

**Current Query:**
```
Human: [User's question]
Assistant:
```

## API Reference

### ChatViewModel

**Key Methods:**
```swift
func sendMessage(_ text: String?)
func stopGeneration()
func regenerateLastResponse()
func selectDocument(_ document: Document)
func createNewConversation()
func loadConversation(_ conversation: Conversation)
func updateParameters(_ params: ModelParameters)
```

**Key Properties:**
```swift
@Published var messages: [ChatMessage]
@Published var selectedDocuments: [Document]
@Published var isGenerating: Bool
@Published var currentConversation: Conversation?
@Published var modelParameters: ModelParameters
```

### LLMService

**Core Method:**
```swift
func generateResponse(
    query: String,
    context: [Document],
    conversationHistory: [ChatMessage],
    parameters: ModelParameters
) -> AsyncThrowingStream<String, Error>
```

### ModelParameters

**Properties:**
```swift
var temperature: Float        // 0.0 - 2.0
var maxTokens: Int           // 1 - 8192
var topP: Float              // 0.0 - 1.0
var topK: Int                // 1 - 100
var repeatPenalty: Float     // 1.0 - 2.0
var contextSize: Int         // 512 - 8192
```

**Presets:**
```swift
.default    // Temperature: 0.7
.precise    // Temperature: 0.3
.creative   // Temperature: 0.9
```

## Troubleshooting

### Messages Not Sending
- Check if model is loaded (Settings → LLM Model)
- Ensure not already generating (wait for previous response)
- Check for error alerts

### No Documents Available
- Import documents in Documents tab first
- Ensure OCR processing completed
- Refresh document list

### Slow Responses (Production)
- Reduce max tokens in settings
- Use smaller/faster model
- Reduce selected document count
- Clear conversation history

### App Crashes During Generation
- Check device memory
- Reduce model size
- Lower context window
- Use quantized models

## Performance Tips

1. **Document Selection**: Select only relevant documents (1-3 recommended)
2. **Context Length**: Keep conversations under 10 exchanges
3. **Model Size**: Use 2B models for phones, 7B for tablets
4. **Quantization**: Use 4-bit quantization (Q4_K_M)
5. **Batch Size**: Process documents in chunks if large

## What's Next (Phase 3)

Phase 3 will add:
- Advanced search in documents
- Message citations with source pages
- Regenerate with different parameters
- Export conversations
- Document comparison features
- Enhanced prompt templates
- Performance optimizations

## Technical Details

### Streaming Implementation
Uses Swift's AsyncThrowingStream:
```swift
return AsyncThrowingStream { continuation in
    for token in generateTokens() {
        continuation.yield(token)
    }
    continuation.finish()
}
```

### Persistence
- Conversations: UserDefaults (JSON)
- Messages: UserDefaults (JSON)
- Documents: Core Data (from Phase 1)

### Memory Management
- Lazy message loading
- Stream cancellation
- Model unloading support
- Context window limits

## Contributing

To contribute LLM backend integration:
1. Implement `LLMManagerProtocol`
2. Handle model loading from GGUF files
3. Implement token generation
4. Test with various model sizes
5. Submit PR with documentation

## Known Limitations (Phase 2)

1. **Simulated Responses**: Currently in demo mode
2. **No Vector Search**: Simple text inclusion (Phase 4)
3. **Limited Context**: ~4K tokens maximum
4. **No Streaming Stop**: Can cancel but may not stop immediately
5. **Simple Persistence**: UserDefaults instead of Core Data

## License

[Your License Here]

## Acknowledgments

- Built on Phase 1 foundation
- Protocol-oriented design for flexibility
- Ready for llama.cpp or MLC LLM integration
- SwiftUI and Combine throughout

---

**Phase 2 Status**: ✅ Complete and Ready for LLM Integration
**Next Phase**: Enhanced Features and Search (Phase 3)
