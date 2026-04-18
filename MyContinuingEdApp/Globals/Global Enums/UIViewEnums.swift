//
//  UIViewEnums.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/17/26.
//

import Foundation


// MARK: - View Controls

/// Enum used in ActivityReflectionView and related sheets and sub-views for controlling
/// what set of reflection prompts are shown to the user.
///
/// Raw String values are as follows:
///     - builtInPrompts: "Standard Prompts"
///     - userMadePrompts: "Your Prompts"
///     - favoritePrompts: "Favorites"
///
///  - Note: Identifiable conformance is made via the raw value of each case
enum PromptView: String, CaseIterable, Identifiable, Hashable {
    case builtInPrompts = "Standard Prompts"
    case userMadePrompts = "Your Prompts"
    case favoritePrompts = "Favorites"
    
    var id: String { self.rawValue }
}//: ViewType

/// Enum used in PromptResponseView to control whether the user enters a type-written response to a selected
/// prompt or if they choose to record an audio response (Pro subscribers only).
///
/// Raw String values are used as the id property and are as follows:
///     - writtenResponse: "Written Response"
///     - audioResponse: "Audio Response"
enum ResponseEntryType: String, CaseIterable, Identifiable, Hashable {
    case writtenResponse = "Written Response"
    case audioResponse = "Audio Response"
    
    var id: String { self.rawValue }
}//: ResponseEntryType

enum MediaLoadingState: String, CaseIterable {
    case blank, loading, loaded, localOnly, error
}//: CertificateLoadingState


// MARK: - Enum for sheet types
enum SheetType {
    case renewal, issuer, specialCat
}//: SheetType
