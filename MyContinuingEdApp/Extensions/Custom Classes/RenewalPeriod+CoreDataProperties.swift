//
//  RenewalPeriod+CoreDataProperties.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/23/25.
//
//

import Foundation
import CoreData


extension RenewalPeriod {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RenewalPeriod> {
        return NSFetchRequest<RenewalPeriod>(entityName: "RenewalPeriod")
    }

    @NSManaged public var renewalHasLateFeeYN: Bool
    @NSManaged public var lateFeeAmount: Double
    @NSManaged public var lateFeeStartDate: Date?
    @NSManaged public var periodEnd: Date?
    @NSManaged public var periodID: UUID?
    @NSManaged public var periodName: String?
    @NSManaged public var periodStart: Date?
    @NSManaged public var reinstatementHours: Double
    @NSManaged public var reinstateCredential: Bool
    @NSManaged public var cesCompleted: NSSet?
    @NSManaged public var credential: Credential?

}

// MARK: Generated accessors for cesCompleted
extension RenewalPeriod {

    @objc(addCesCompletedObject:)
    @NSManaged public func addToCesCompleted(_ value: CeActivity)

    @objc(removeCesCompletedObject:)
    @NSManaged public func removeFromCesCompleted(_ value: CeActivity)

    @objc(addCesCompleted:)
    @NSManaged public func addToCesCompleted(_ values: NSSet)

    @objc(removeCesCompleted:)
    @NSManaged public func removeFromCesCompleted(_ values: NSSet)

}

extension RenewalPeriod : Identifiable {

}
