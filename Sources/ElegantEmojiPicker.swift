//
//  ElegantEmojiPicker.swift
//  Demo
//
//  Created by Grant Oganyan on 3/10/23.
//

import Foundation
import UIKit

/// Present this view controller when you want to offer users emoji selection. Conform to its delegate ElegantEmojiPickerDelegate and pass it to the view controller to interact with it and receive user's selection. 
open class ElegantEmojiPicker: UINavigationController {
    
    public weak var pickerDelegate: ElegantEmojiPickerDelegate? {
        didSet {
            pickerViewController.delegate = pickerDelegate
        }
    }
    
    private let pickerViewController: ElegantEmojiPickerViewController
    
    /// Shared instance for delegate callbacks
    internal static var shared: ElegantEmojiPicker!
    
    /// Initialize and present this view controller to offer emoji selection to users.
    /// - Parameters:
    ///   - delegate: provide a delegate to interact with the picker
    ///   - sourceView: provide a source view for a popover presentation style.
    ///   - sourceNavigationBarButton: provide a source navigation bar button for a popover presentation style.
    public init(delegate: ElegantEmojiPickerDelegate? = nil, sourceView: UIView? = nil, sourceNavigationBarButton: UIBarButtonItem? = nil) {
        
        self.pickerViewController = ElegantEmojiPickerViewController(delegate: delegate)
        
        super.init(rootViewController: pickerViewController)
        
        ElegantEmojiPicker.shared = self
        self.pickerDelegate = delegate
        
        // Setup emoji sections after shared instance is set
        pickerViewController.setupEmojiSections()
        
        if let sourceView = sourceView, !AppConfiguration.isIPhone, AppConfiguration.windowFrame.width > 500 {
            self.modalPresentationStyle = .popover
            self.popoverPresentationController?.sourceView = sourceView
        } else if let sourceNavigationBarButton = sourceNavigationBarButton, !AppConfiguration.isIPhone, AppConfiguration.windowFrame.width > 500 {
            self.modalPresentationStyle = .popover
            self.popoverPresentationController?.barButtonItem = sourceNavigationBarButton
        } else {
            self.modalPresentationStyle = .formSheet
            if #available(iOS 15.0, *) {
                self.sheetPresentationController?.prefersGrabberVisible = true
                self.sheetPresentationController?.detents = [.medium(), .large()]
            }
        }
        
        self.presentationController?.delegate = self
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        self.view.backgroundColor = UIScreen.main.traitCollection.userInterfaceStyle == .light ? .black.withAlphaComponent(0.1) : .clear
    }
}

extension ElegantEmojiPicker: UIAdaptivePresentationControllerDelegate {
    public func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none // Do not adapt presentation style. We set the presentation style manually in our init().
    }
}

//MARK: Static methods

extension ElegantEmojiPicker {
    
    /// Persists skin tone for a specified emoji.
    /// - Parameters:
    ///   - originalEmoji: Standard yellow emoji for which to persist a skin tone.
    ///   - skinTone: Skin tone to save. Pass nil to remove saved skin tone.
    static public func PersistSkinTone (originalEmoji: Emoji, skinTone: EmojiSkinTone?) {
        ElegantEmojiPicker.persistedSkinTones[originalEmoji.description] = skinTone?.rawValue
    }
    
    /// Delete all persisted emoji skin tones.
    static public func CleanPersistedSkinTones () {
        ElegantEmojiPicker.persistedSkinTones = [:]
    }
    
    /// Dictionary containing all emojis with persisted skin tones. [Emoji : Skin tone]
    static public var persistedSkinTones: [String:String] {
        get { return UserDefaults.standard.object(forKey: "Finalet_Elegant_Emoji_Picker_Skin_Tones_Key") as? [String:String] ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: "Finalet_Elegant_Emoji_Picker_Skin_Tones_Key") }
    }
    
    /// Returns an array of all available emojis. Use this method to retrieve emojis for your own collection.
    /// - Returns: Array of all emojis.
    static public func getAllEmoji () -> [Emoji] {
        let emojiData = (try? Data(contentsOf: Bundle.module.url(forResource: "Emoji Unicode 16.0", withExtension: "json")!))!
        return try! JSONDecoder().decode([Emoji].self, from: emojiData)
    }
    
    /// Returns an array of all available emojis categorized by section.
    /// - Returns: Array of default sections [EmojiSection] containing all available emojis.
    static public func getDefaultEmojiSections() -> [EmojiSection]  {
        var emojis = getAllEmoji()
        
        let persistedSkinTones = ElegantEmojiPicker.persistedSkinTones
        emojis = emojis.map({
            if !$0.supportsSkinTones { return $0 }
            
            if let persistedSkinToneStr = persistedSkinTones[$0.description], let persistedSkinTone = EmojiSkinTone(rawValue: persistedSkinToneStr) {
                return $0.duplicate(persistedSkinTone)
            }
            
            return $0
        })
        
        var emojiSections = [EmojiSection]()
        
        let currentIOSVersion = UIDevice.current.systemVersion
        let defaultCategories: [EmojiCategory] = [.SmileysAndEmotion, .PeopleAndBody, .AnimalsAndNature, .FoodAndDrink, .TravelAndPlaces, .Activities, .Objects, .Symbols, .Flags]
        
        for emoji in emojis {
            if emoji.iOSVersion.compare(currentIOSVersion, options: .numeric) == .orderedDescending { continue } // Skip unsupported emojis.
            
            let localizedCategoryTitle = EmojiPickerLocalization.categoryTitle(for: emoji.category)
            
            if let section = emojiSections.firstIndex(where: { $0.title == localizedCategoryTitle }) {
                emojiSections[section].emojis.append(emoji)
            } else if defaultCategories.contains(emoji.category) {
                emojiSections.append(
                    EmojiSection(title: localizedCategoryTitle, icon: emoji.category.image, emojis: [emoji])
                )
            }
        }
        
        return emojiSections
    }
    
    /// Get emoji search results for a given prompt, using the default search algorithm. First looks for matches in aliases, then in tags, and lastly in description. Sorts search results by relevance.
    /// - Parameters:
    ///   - prompt: Search prompt to use.
    ///   - fromAvailable: Which emojis to search from.
    /// - Returns: Array of [Emoji] that were found.
    static public func getSearchResults (_ prompt: String, fromAvailable: [EmojiSection] ) -> [Emoji] {
        if prompt.isEmpty || prompt == " " { return []}
        
        var cleanSearchTerm = prompt.lowercased()
        if cleanSearchTerm.last == " " { cleanSearchTerm.removeLast() }
        
        var results = [Emoji]()

        for section in fromAvailable {
            results.append(contentsOf: section.emojis.filter {
                $0.aliases.contains(where: { $0.localizedCaseInsensitiveContains(cleanSearchTerm) }) ||
                $0.tags.contains(where: { $0.localizedCaseInsensitiveContains(cleanSearchTerm) }) ||
                $0.description.localizedCaseInsensitiveContains(cleanSearchTerm)
            })
        }
        
        return results.sorted { sortSearchResults($0, $1, prompt: cleanSearchTerm) }
    }
    
    static func sortSearchResults (_ first: Emoji, _ second: Emoji, prompt: String) -> Bool {
        let regExp = "\\b\(prompt)\\b"
        
        // The emoji which contains the exact search prompt in its aliases (first priority), tags (second priority), or description (lowest priority) wins. If both contain it, return the shorted described emoji, since that is usually more accurate.
        
        if first.aliases.contains(where: { $0.range(of: regExp, options: .regularExpression) != nil }) {
            if second.aliases.contains(where: { $0.range(of: regExp, options: .regularExpression) != nil }) {
                return first.description.count < second.description.count
            }
            return true
        } else if second.aliases.contains(where: { $0.range(of: regExp, options: .regularExpression) != nil }) {
            return false
        }
        
        if first.tags.contains(where: { $0.range(of: regExp, options: .regularExpression) != nil }) {
            if second.tags.contains(where: { $0.range(of: regExp, options: .regularExpression) != nil }) {
                return first.description.count < second.description.count
            }
            return true
        } else if second.tags.contains(where: { $0.range(of: regExp, options: .regularExpression) != nil }) {
            return false
        }
        
        if let _ = first.description.range(of: regExp, options: .regularExpression) {
            if let _ = second.description.range(of: regExp, options: .regularExpression) {
                return first.description.count < second.description.count
            }
            return true
        } else if let _ = second.description.range(of: regExp, options: .regularExpression) {
            return false
        }
        
        return false
    }
}
