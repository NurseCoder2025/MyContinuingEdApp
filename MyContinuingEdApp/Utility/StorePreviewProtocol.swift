//
//  StorePreviewProtocol.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 12/4/25.
//

import Foundation

protocol StorePreviewProtocol: Identifiable, Hashable, Equatable, Sendable {
    var id: String {get}
    var displayName: String {get}
    var description: String {get}
    var price: Decimal {get}
    var displayPrice: String {get}
}
