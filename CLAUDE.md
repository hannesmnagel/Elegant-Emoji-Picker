# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Elegant Emoji Picker is a Swift Package for iOS/iPadOS/MacCatalyst that provides a configurable emoji picker UIKit component. The library supports Unicode 16.0 emojis, skin tone variations, search functionality, and various customization options.

**Key Features:**
- Emoji picker navigation controller with delegate pattern
- Native iOS search functionality with UISearchController
- Skin tone support (one per emoji, not two-tone combinations)
- Categories toolbar with sections
- Long press preview functionality
- Dynamic navigation title showing current category
- Localization support
- Latest Unicode 16.0 emoji support

## Architecture

### Core Components

**Main Classes:**
- `ElegantEmojiPicker`: Main UINavigationController that presents the emoji picker interface
- `ElegantEmojiPickerViewController`: Internal view controller handling the emoji grid and interactions
- `ElegantEmojiPickerDelegate`: Protocol for handling emoji selection and customization
- `Emoji`: Data structure representing individual emojis with metadata
- `EmojiSection`: Groups of emojis organized by category
- `ElegantLocalization`: Localization strings for UI elements

**UI Elements (Sources/Elements/):**
- `EmojiCell`: Collection view cell for displaying individual emojis
- `CollectionViewSectionHeader`: Section headers in the emoji grid
- `EmojiPreview`: Long-press preview component
- `SectionsToolbar`: Category navigation toolbar
- `SkinToneSelector`: UI for selecting emoji skin tones

**Extensions (Sources/Extensions/):**
- `AppConfiguration.swift`: App-level configuration utilities
- `AutoLayout.swift`: Auto layout helper extensions
- `UIColor+Extensions.swift`: Color utility extensions  
- `UIView+Extensions.swift`: View utility extensions

### Data Flow

1. `ElegantEmojiPicker` (UINavigationController) creates and manages `ElegantEmojiPickerViewController`
2. Internal view controller loads emoji data from `Emoji Unicode 16.0.json`
3. Navigation title dynamically updates to show current emoji category
4. Delegate methods allow customization of emoji sections and search behavior
5. User interactions (selection, search, preview) are communicated through delegate callbacks
6. Localization objects control UI text

## Development Commands

### Building the Package
```bash
# Build the Swift package
swift build

# Build for specific platform
swift build --triple arm64-apple-ios13.0
```

### Demo App
The demo app is located in the `Demo/` directory and requires Xcode to build:
```bash
# Open demo project in Xcode
open Demo/Demo.xcodeproj

# Build and run from command line (if xcodebuild is preferred)
cd Demo
xcodebuild -project Demo.xcodeproj -scheme Demo -destination "platform=iOS Simulator,name=iPhone 15"
```

### Testing
No formal test suite is currently implemented. Testing is done through the demo app.

## Key Implementation Details

### Emoji Data Structure
- Emojis are loaded from `Sources/Resources/Emoji Unicode 16.0.json`
- Each emoji contains: unicode string, description, category, aliases, tags, skin tone support, iOS version
- Skin tone application uses Unicode scalar manipulation for proper rendering

### Delegate Pattern
The library uses a comprehensive delegate pattern with optional methods:
- Required: `emojiPicker(_:didSelectEmoji:)` for handling selection
- Optional: Custom emoji loading, search algorithms, preview handling, UI state changes

### Simplified Architecture
- No configuration complexity - sensible defaults with search, categories, and skin tones enabled
- `ElegantLocalization`: Provides custom text for all UI labels
- Emoji sections can be completely customized through delegate methods
- Navigation controller automatically handles cancel button and search bar

### UI Architecture
- Collection view-based layout with flow layout
- Visual effect blur backgrounds for modern iOS appearance
- Constraint-based layout using programmatic Auto Layout
- Support for both portrait and landscape orientations

## Platform Support

- **Minimum iOS**: 13.0
- **Minimum macCatalyst**: 13.0  
- **Swift Tools Version**: 5.7
- **Framework**: UIKit (not SwiftUI)

## Dependencies

This package has no external dependencies - it's built entirely with iOS SDK frameworks.
