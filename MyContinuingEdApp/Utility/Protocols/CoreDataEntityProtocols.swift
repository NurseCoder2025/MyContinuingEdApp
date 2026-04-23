//
//  CoreDataEntityProtocols.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/18/26.
//

import Foundation


protocol DelayedParentObjDeletion: DelayedDeletion {
    func prepareForDeletion(dataController: DataController) async
}//: DelayedDeletion

protocol DelayedDeletion {
    var isMarkedForDeletion: Bool { get set }
    var deletionTimeStamp: Date? { get set }
}//: DelayedDeletionSubItem
