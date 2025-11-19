# TalkGPT iOS App - Design Document

## 1. Executive Summary

TalkGPT is an iOS application that leverages on-device machine learning models to provide document understanding and conversational Q&A capabilities. The app operates entirely offline, ensuring privacy and speed by utilizing local ML models for OCR, document processing, and natural language understanding.

**Key Features:**
- Multi-page document scanning and import
- On-device OCR and document understanding
- Conversational Q&A with documents using local LLM
- Privacy-focused: All processing happens on-device
- Offline-first architecture

---

## 2. Technology Stack

### 2.1 Core Frameworks
- **Language**: Swift 5.9+
- **Minimum iOS Version**: iOS 16.0+
- **UI Framework**: SwiftUI
- **Architecture Pattern**: MVVM with Combine

### 2.2 Machine Learning Frameworks

#### Document Understanding
- **Primary Option**: Apple Vision Framework + VisionKit
  - `VNDocumentCameraViewController` for document scanning
  - `VNRecognizeTextRequest` for OCR
  - Native, optimized, and well-integrated with iOS

- **Alternative Option**: Google ML Kit Vision API
  - Text Recognition API
  - Document Scanner API
  - Digital Ink Recognition (if needed)

#### Language Model
- **Primary Option**: Core ML with quantized LLM
  - Use llama.cpp Swift bindings or MLC LLM
  - Deploy quantized Gemma 2B or Phi-3 models
  - Leverage Neural Engine for acceleration

- **Alternative Option**: Google ML Kit Natural Language API
  - Smart Reply
  - Entity Extraction
  - Limited compared to full LLM capabilities

### 2.3 Data Storage

#### Document Storage
- **FileManager**: Store PDF/image files
- **Core Data**: Store document metadata and extracted text
  - Document entity (id, name, createdDate, pageCount, etc.)
  - Page entity (id, documentId, pageNumber, text, imagePath)

#### Vector Database (Optional - Phase 2)
- **Option 1**: Core Data + Custom Vector Search
  - Store embeddings as binary data
  - Implement cosine similarity in Swift

- **Option 2**: SQLite with Extension
  - Use sqlite-vss (Vector Similarity Search)
  - More efficient for large document collections

- **Option 3**: In-Memory Vector Store
  - Simple array-based storage for small document sets
  - Generate embeddings using on-device model

**Recommendation**: Start without vector DB (Phase 1), use simple text search. Add vector search in Phase 2 if needed.

### 2.4 Additional Dependencies
- **PDFKit**: PDF rendering and manipulation
- **Combine**: Reactive data flow
- **CryptoKit**: Optional data encryption at rest

---

## 3. Architecture Overview

### 3.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  Documents   │  │     Chat     │  │   Settings   │  │
│  │     View     │  │     View     │  │     View     │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
                          │
┌─────────────────────────────────────────────────────────┐
│                    ViewModel Layer                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  Documents   │  │     Chat     │  │   Settings   │  │
│  │  ViewModel   │  │  ViewModel   │  │  ViewModel   │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
                          │
┌─────────────────────────────────────────────────────────┐
│                     Service Layer                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   Document   │  │     LLM      │  │   Storage    │  │
│  │   Service    │  │   Service    │  │   Service    │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
                          │
┌─────────────────────────────────────────────────────────┐
│                      ML Layer                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │     OCR      │  │     LLM      │  │  Embedding   │  │
│  │   Manager    │  │   Manager    │  │   Manager    │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
                          │
┌─────────────────────────────────────────────────────────┐
│                      Data Layer                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  Core Data   │  │ FileManager  │  │   Vector DB  │  │
│  │   Manager    │  │   Manager    │  │  (Optional)  │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### 3.2 Data Flow

#### Document Import Flow
```
1. User selects camera/file → DocumentsView
2. DocumentsViewModel calls DocumentService.importDocument()
3. DocumentService:
   a. Save raw file (FileManager)
   b. Call OCRManager.extractText()
   c. Save metadata + text (CoreDataManager)
   d. [Optional] Call EmbeddingManager.generateEmbeddings()
4. Update UI with new document
```

#### Chat Flow
```
1. User selects documents + enters query → ChatView
2. ChatViewModel calls LLMService.generateResponse()
3. LLMService:
   a. Retrieve document context (StorageService)
   b. [Optional] Perform semantic search (VectorDB)
   c. Build prompt with context
   d. Call LLMManager.generate()
   e. Stream response back to UI
4. Display response with streaming
```

---

## 4. Module Design

### 4.1 Presentation Layer

#### 4.1.1 DocumentsView
**Responsibilities:**
- Display list of imported documents
- Provide document import options (camera/file browser)
- Show document details (preview, metadata)
- Handle document deletion

**UI Components:**
- Document list (LazyVStack/List)
- Floating action button (camera/import menu)
- Document detail sheet
- Camera scanner modal

#### 4.1.2 ChatView
**Responsibilities:**
- Display conversation history
- Document selection interface
- Message input field
- Streaming response display

**UI Components:**
- Message list (ScrollView with reverse order)
- Document selector (horizontal ScrollView)
- Input field with send button
- Typing indicator during generation
- Context display (selected documents)

#### 4.1.3 SettingsView
**Responsibilities:**
- Model settings (temperature, max tokens)
- Storage management
- About/version info
- Clear data options

### 4.2 ViewModel Layer

#### 4.2.1 DocumentsViewModel
```swift
class DocumentsViewModel: ObservableObject {
    @Published var documents: [Document]
    @Published var isImporting: Bool
    @Published var isProcessing: Bool
    @Published var errorMessage: String?

    private let documentService: DocumentService

    func importFromCamera()
    func importFromFiles()
    func deleteDocument(_ document: Document)
    func refreshDocuments()
}
```

#### 4.2.2 ChatViewModel
```swift
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage]
    @Published var selectedDocuments: [Document]
    @Published var isGenerating: Bool
    @Published var currentInput: String

    private let llmService: LLMService
    private let storageService: StorageService

    func sendMessage(_ text: String)
    func selectDocument(_ document: Document)
    func clearConversation()
    func stopGeneration()
}
```

### 4.3 Service Layer

#### 4.3.1 DocumentService
```swift
protocol DocumentService {
    func importDocument(from source: DocumentSource) async throws -> Document
    func processDocument(_ document: Document) async throws
    func deleteDocument(_ documentId: UUID) async throws
    func getAllDocuments() async throws -> [Document]
}

enum DocumentSource {
    case camera([UIImage])
    case file(URL)
}
```

#### 4.3.2 LLMService
```swift
protocol LLMService {
    func generateResponse(
        query: String,
        context: [Document],
        conversationHistory: [ChatMessage]
    ) -> AsyncThrowingStream<String, Error>

    func stopGeneration()
    func updateModelParameters(_ params: ModelParameters)
}

struct ModelParameters {
    var temperature: Float
    var maxTokens: Int
    var topP: Float
}
```

#### 4.3.3 StorageService
```swift
protocol StorageService {
    func saveDocument(_ document: Document) async throws
    func fetchDocument(_ id: UUID) async throws -> Document?
    func fetchAllDocuments() async throws -> [Document]
    func deleteDocument(_ id: UUID) async throws
    func saveConversation(_ conversation: Conversation) async throws
}
```

### 4.4 ML Layer

#### 4.4.1 OCRManager
```swift
class OCRManager {
    func extractText(from images: [UIImage]) async throws -> [PageText]
    func extractText(from pdf: URL) async throws -> [PageText]
}

struct PageText {
    let pageNumber: Int
    let text: String
    let confidence: Float
    let boundingBoxes: [TextBlock]?
}
```

#### 4.4.2 LLMManager
```swift
class LLMManager {
    func loadModel(modelPath: URL) async throws
    func generate(
        prompt: String,
        parameters: ModelParameters
    ) -> AsyncThrowingStream<String, Error>

    func unloadModel()
}
```

#### 4.4.3 EmbeddingManager (Phase 2)
```swift
class EmbeddingManager {
    func generateEmbeddings(text: String) async throws -> [Float]
    func batchGenerateEmbeddings(texts: [String]) async throws -> [[Float]]
}
```

### 4.5 Data Layer

#### 4.5.1 Core Data Models

```swift
@Entity Document {
    @ID var id: UUID
    var name: String
    var createdDate: Date
    var fileURL: URL
    var pageCount: Int
    var totalCharacters: Int
    @Relationship var pages: [Page]
}

@Entity Page {
    @ID var id: UUID
    var pageNumber: Int
    var text: String
    var imageURL: URL?
    var embedding: Data? // [Float] serialized
    @Relationship var document: Document
}

@Entity Conversation {
    @ID var id: UUID
    var createdDate: Date
    @Relationship var messages: [ChatMessage]
}

@Entity ChatMessage {
    @ID var id: UUID
    var role: MessageRole // user/assistant
    var content: String
    var timestamp: Date
    var documentReferences: [UUID] // Document IDs
}
```

---

## 5. UI/UX Design

### 5.1 Tab Structure

```
┌─────────────────────────────────────┐
│                                     │
│         Main Content Area           │
│                                     │
│                                     │
└─────────────────────────────────────┘
┌─────────────────────────────────────┐
│  📄 Documents  💬 Chat  ⚙️ Settings │
└─────────────────────────────────────┘
```

### 5.2 Documents Tab

**Layout:**
- Navigation bar with title "My Documents"
- Grid/List view of documents with:
  - Thumbnail preview
  - Document name
  - Page count
  - Date added
- Floating action button (FAB) with:
  - Camera scan option
  - File import option
  - Photo library option

**Interactions:**
- Tap document → Show detail view with:
  - Full-page previews
  - Extracted text view
  - Option to re-process
  - Delete option
- Long press → Quick actions (delete, share)
- Pull to refresh

### 5.3 Chat Tab

**Layout:**
- Document selector bar (horizontal scrollable chips)
  - Shows selected documents
  - Tap to add/remove
- Chat message list (reverse chronological)
  - User messages (right-aligned, blue)
  - Assistant messages (left-aligned, gray)
  - Context references (small chips below messages)
- Input bar at bottom:
  - Text field
  - Send button
  - Stop button (during generation)

**Interactions:**
- Tap document chip → Open document selector modal
- Tap message → Show full text (for long messages)
- Pull to load older messages
- Long press message → Copy text

### 5.4 Settings Tab

**Sections:**
1. Model Settings
   - Temperature slider
   - Max response length
   - Context window size

2. Storage
   - Total documents count
   - Storage used
   - Clear all data button

3. About
   - App version
   - Model information
   - Privacy policy
   - Licenses

---

## 6. Implementation Phases

### Phase 1: Foundation & Document Processing (Weeks 1-3)

**Objectives:**
- Set up project structure and core architecture
- Implement document import and OCR
- Basic UI for document management

**Tasks:**
1. **Week 1: Project Setup**
   - Create Xcode project with SwiftUI
   - Set up Core Data schema
   - Implement FileManager wrapper
   - Create base MVVM structure
   - Set up tab navigation

2. **Week 2: Document Import**
   - Integrate VNDocumentCameraViewController
   - Implement file picker integration
   - Create DocumentService
   - Implement OCRManager with Vision framework
   - Add progress indicators

3. **Week 3: Document Management**
   - Build DocumentsView UI
   - Implement document list and grid views
   - Add document detail view
   - Implement delete functionality
   - Add document preview using PDFKit

**Deliverables:**
- Working document import from camera and files
- OCR text extraction from images and PDFs
- Document storage and management
- Basic UI for viewing documents

### Phase 2: LLM Integration & Basic Chat (Weeks 4-6)

**Objectives:**
- Integrate on-device LLM
- Implement basic chat functionality
- Connect documents with chat context

**Tasks:**
1. **Week 4: LLM Setup**
   - Evaluate and select LLM solution (llama.cpp vs MLC LLM)
   - Download and quantize model (Gemma 2B or Phi-3)
   - Create LLMManager wrapper
   - Implement model loading and inference
   - Test response generation

2. **Week 5: Chat Service**
   - Create LLMService
   - Implement prompt engineering for document Q&A
   - Add conversation history management
   - Implement streaming response handling
   - Create ChatViewModel

3. **Week 6: Chat UI**
   - Build ChatView with message list
   - Implement document selector
   - Add message input field
   - Implement streaming response display
   - Add conversation persistence

**Deliverables:**
- Working on-device LLM inference
- Chat interface with streaming responses
- Document selection and context injection
- Basic Q&A capabilities

### Phase 3: Enhanced Features (Weeks 7-9)

**Objectives:**
- Improve search and retrieval
- Add advanced chat features
- Optimize performance

**Tasks:**
1. **Week 7: Smart Search**
   - Implement basic keyword search in documents
   - Add text highlighting in document viewer
   - Create search UI in DocumentsView
   - Add "jump to page" from chat references

2. **Week 8: Chat Enhancements**
   - Add conversation management (new/delete/rename)
   - Implement conversation history view
   - Add message citations (source page references)
   - Implement regenerate response
   - Add copy/share message functionality

3. **Week 9: Performance & Polish**
   - Optimize OCR performance (batch processing)
   - Implement model caching strategies
   - Add loading states and error handling
   - Optimize memory usage for large documents
   - UI/UX refinements

**Deliverables:**
- Document search functionality
- Enhanced chat features
- Improved performance and stability
- Polished user experience

### Phase 4: Advanced Features (Weeks 10-12) - Optional

**Objectives:**
- Add vector search capabilities
- Implement advanced ML features
- Add export and sharing

**Tasks:**
1. **Week 10: Vector Search**
   - Integrate embedding model (Core ML)
   - Implement EmbeddingManager
   - Set up vector storage (SQLite-vss or in-memory)
   - Implement semantic search
   - Compare with keyword search

2. **Week 11: Advanced Features**
   - Multi-document synthesis
   - Document summarization
   - Table/chart extraction from images
   - Handwriting recognition (if needed)

3. **Week 12: Export & Sharing**
   - Export conversations as PDF/text
   - Share documents and chats
   - iCloud sync (optional)
   - Settings customization

**Deliverables:**
- Semantic search with vector embeddings
- Advanced document understanding
- Export and sharing capabilities
- Feature-complete app

---

## 7. Technical Considerations

### 7.1 Performance

**Challenges:**
- LLM inference on mobile devices
- Large document processing
- Memory constraints

**Solutions:**
- Use quantized models (4-bit or 8-bit)
- Implement pagination for large documents
- Lazy loading of document content
- Background processing for OCR
- Model unloading when not in use
- Chunk large documents for context

### 7.2 Privacy & Security

**Approach:**
- All processing on-device (no cloud)
- Optional encryption at rest using CryptoKit
- No analytics or telemetry by default
- Clear data deletion
- Secure file storage in app sandbox

### 7.3 Model Selection

**Recommended Models:**

1. **LLM Options:**
   - **Gemma 2B (4-bit)**: ~1.2GB, good balance
   - **Phi-3 Mini (4-bit)**: ~2GB, better quality
   - **TinyLlama 1.1B**: ~600MB, faster but less capable

2. **Embedding Options (Phase 4):**
   - **Sentence Transformers (Core ML)**: all-MiniLM-L6-v2
   - **Apple's NaturalLanguage framework**: Basic embeddings

**Selection Criteria:**
- Model size vs. device storage
- Inference speed on target devices (iPhone 12+)
- Quality of responses
- Context window size

### 7.4 Testing Strategy

**Unit Tests:**
- Service layer logic
- Data model transformations
- Prompt engineering functions

**Integration Tests:**
- OCR accuracy
- LLM response quality
- Data persistence

**UI Tests:**
- Critical user flows
- Tab navigation
- Document import flow
- Chat interaction

**Performance Tests:**
- Model loading time
- Inference latency
- Memory usage
- Battery impact

---

## 8. Future Enhancements

### 8.1 Short-term
- Support for more file formats (DOCX, TXT, images)
- Voice input for chat
- Dark mode support
- iPad optimization with split view
- Folder organization for documents

### 8.2 Long-term
- Multi-language support
- Custom model fine-tuning
- Collaborative features (shared documents)
- Integration with other apps (Files app, share extension)
- Web-based document import
- Smart suggestions and autocomplete
- Document comparison and diff
- OCR quality improvement with user corrections

---

## 9. Success Metrics

**Technical Metrics:**
- OCR accuracy > 95%
- Average response time < 3 seconds
- App size < 200MB (excluding models)
- Memory usage < 500MB during inference
- Crash-free rate > 99%

**User Experience Metrics:**
- Document import success rate
- Average documents per user
- Chat engagement (messages per session)
- Feature adoption rates
- User retention

---

## 10. Risks & Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Model too large for devices | High | Use quantization, offer model options |
| Slow inference times | High | Optimize model, use Neural Engine, set expectations |
| Poor OCR accuracy | Medium | Use Apple Vision (high quality), allow re-scan |
| Insufficient context window | Medium | Implement smart chunking, vector search |
| App size too large | Medium | Dynamic model download, on-demand features |
| Battery drain | Medium | Optimize inference, background processing limits |
| Complex UX | Low | User testing, iterative design |

---

## 11. Conclusion

TalkGPT represents a privacy-focused approach to document understanding and conversational AI on iOS. By leveraging on-device ML models, the app ensures user data remains private while providing powerful document Q&A capabilities. The modular architecture and phased implementation plan allow for iterative development and testing, ensuring a high-quality user experience.

The design prioritizes:
1. **Privacy**: All processing on-device
2. **Performance**: Optimized models and efficient architecture
3. **Usability**: Clean, intuitive interface
4. **Extensibility**: Modular design for future enhancements

With careful implementation and testing, TalkGPT can become a valuable tool for users who need to quickly understand and interact with their documents without compromising privacy.

---

## Appendix A: File Structure

```
TalkGPT/
├── App/
│   ├── TalkGPTApp.swift
│   └── AppDelegate.swift
├── Models/
│   ├── Domain/
│   │   ├── Document.swift
│   │   ├── Page.swift
│   │   ├── ChatMessage.swift
│   │   └── Conversation.swift
│   └── CoreData/
│       └── TalkGPT.xcdatamodeld
├── Views/
│   ├── Documents/
│   │   ├── DocumentsView.swift
│   │   ├── DocumentDetailView.swift
│   │   └── DocumentCardView.swift
│   ├── Chat/
│   │   ├── ChatView.swift
│   │   ├── MessageRow.swift
│   │   └── DocumentSelectorView.swift
│   ├── Settings/
│   │   └── SettingsView.swift
│   └── Common/
│       ├── LoadingView.swift
│       └── ErrorView.swift
├── ViewModels/
│   ├── DocumentsViewModel.swift
│   ├── ChatViewModel.swift
│   └── SettingsViewModel.swift
├── Services/
│   ├── DocumentService.swift
│   ├── LLMService.swift
│   └── StorageService.swift
├── ML/
│   ├── OCRManager.swift
│   ├── LLMManager.swift
│   └── EmbeddingManager.swift
├── Data/
│   ├── CoreDataManager.swift
│   ├── FileManagerHelper.swift
│   └── VectorStore.swift (Phase 4)
├── Utilities/
│   ├── Constants.swift
│   ├── Extensions/
│   └── Logging.swift
├── Resources/
│   ├── Models/
│   │   └── (ML models placed here)
│   └── Assets.xcassets
└── Tests/
    ├── UnitTests/
    ├── IntegrationTests/
    └── UITests/
```

---

## Appendix B: Key Dependencies

```swift
// Package.swift dependencies

dependencies: [
    // For llama.cpp integration
    .package(url: "https://github.com/ggerganov/llama.cpp", from: "1.0.0"),

    // Or for MLC LLM
    .package(url: "https://github.com/mlc-ai/mlc-llm", from: "1.0.0"),

    // For vector search (Phase 4)
    .package(url: "https://github.com/1024jp/GzipSwift", from: "5.0.0"),
]
```

---

**Document Version**: 1.0
**Last Updated**: 2025-11-19
**Author**: TalkGPT Development Team
**Status**: Draft for Review
