//
//  Localization.swift
//  ElegantEmojiPicker
//
//  Created by Grant Oganyan on 3/10/23.
//

import Foundation

extension String {
    /// Returns a localized string from the ElegantEmojiPicker bundle
    var localized: String {
        return NSLocalizedString(self, bundle: Bundle.module, comment: "")
    }
}

/// Helper class for accessing localized strings
struct EmojiPickerLocalization {
    static let searchPlaceholder = "search_placeholder".localized
    static let searchResultsTitle = "search_results_title".localized
    static let searchResultsEmpty = "search_results_empty".localized
    
    static func categoryTitle(for category: EmojiCategory) -> String {
        switch category {
        case .SmileysAndEmotion:
            return "category_smileys_emotion".localized
        case .PeopleAndBody:
            return "category_people_body".localized
        case .AnimalsAndNature:
            return "category_animals_nature".localized
        case .FoodAndDrink:
            return "category_food_drink".localized
        case .TravelAndPlaces:
            return "category_travel_places".localized
        case .Activities:
            return "category_activities".localized
        case .Objects:
            return "category_objects".localized
        case .Symbols:
            return "category_symbols".localized
        case .Flags:
            return "category_flags".localized
        }
    }
}