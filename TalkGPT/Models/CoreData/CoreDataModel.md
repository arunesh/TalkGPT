# Core Data Model Setup Instructions

Since we're creating this project outside of Xcode, you'll need to create the Core Data model file manually in Xcode.

## Steps to Create TalkGPT.xcdatamodeld

1. In Xcode, create a new Data Model file: File > New > File > Data Model
2. Name it `TalkGPT.xcdatamodeld`
3. Place it in `TalkGPT/Models/CoreData/` directory

## Entities to Create

### DocumentEntity

**Attributes:**
- `id`: UUID (required)
- `name`: String (required)
- `createdDate`: Date (required)
- `fileURL`: String (required)
- `pageCount`: Integer 32 (default: 0)
- `totalCharacters`: Integer 32 (default: 0)
- `thumbnailURL`: String (optional)

**Relationships:**
- `pages`: To-Many relationship to PageEntity (inverse: document, cascade delete)

### PageEntity

**Attributes:**
- `id`: UUID (required)
- `documentId`: UUID (required)
- `pageNumber`: Integer 32 (required)
- `text`: String (required)
- `imageURL`: String (optional)
- `confidence`: Float (default: 0.0)
- `embedding`: Binary Data (optional, for Phase 4)

**Relationships:**
- `document`: To-One relationship to DocumentEntity (inverse: pages)

## Code Generation

In the Xcode Data Model Inspector for each entity:
1. Set "Codegen" to "Manual/None" (we've already created the classes)
2. Set "Class Name" to match the entity name (DocumentEntity, PageEntity)
3. Set "Module" to "TalkGPT"

## Alternative: Programmatic Model Creation

If you prefer to create the model programmatically without Xcode, you can use the code in `ProgrammaticCoreDataModel.swift` to define the model in code.
