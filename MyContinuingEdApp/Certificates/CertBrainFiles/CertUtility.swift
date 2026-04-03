//
//  CertUtility.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 3/31/26.
//

import CoreData
import Foundation
import UIKit


final class CertUtility {
    // MARK: - PROPERTIES
    
    private let dataController: DataController
    private let certBrain: CertificateBrain
    private let coordManager: CertCoordinatorManager
    
    private let fileSystem = FileManager()
    
    // MARK: - Metadata
    
    func extractMetadataFromDoc(at url: URL) async -> CertificateMetadata {
        var extractedMetaData: CertificateMetadata = CertificateMetadata.example
        let savedCertDoc = await CertificateDocument(certURL: url)
        if await savedCertDoc.open() {
            extractedMetaData = await savedCertDoc.certMetaData
        }//: closure
        await savedCertDoc.close()
        
        // Logging to help track why metadata reading failed
        if extractedMetaData.isExampleOnly {
            NSLog(">>>Error extracting certificate metadata. Returning example object instead.")
            NSLog(">>>Issue came at the following CertificateDocument URL: \(url.absoluteString)")
        }//: IF (isExampleOnly)
        
        return extractedMetaData
    }//: extractMetadataFromDoc
    
    // MARK: - Certificate Confirmation
    
    /// Method for determining if an individual CeActivity has a certificate saved for it, based on a matching coordinator object.
    /// - Parameter activity: CeActivity that is to be checked for a CE certificate
    /// - Returns: True if a matching coordinator can be found and the CertiifcateDocument can be opened at the
    /// coordinator's fileURL property.  False if otherwise.
    func ceActivityHasCertificateSaved(_ activity: CeActivity) async -> Bool {
        if coordManager.currentCoordinators.isEmpty {
            await coordManager.decodeCoordinatorList()
        }//: IF (.isEmpty))
        
        let coordinators = coordManager.currentCoordinators
        guard coordinators.isNotEmpty else { return false }
        
        let matchingCoordinator = coordinators.first { coordinator in
            coordinator.assignedObjectID == activity.activityID
        }//: closure
        
        guard let foundCoordinator = matchingCoordinator else { return false }
        
        let savedCert = await CertificateDocument(certURL: foundCoordinator.fileURL)
        if await savedCert.open() {
            await savedCert.close()
            return true
        } else {
            return false
        }//: IF await
    }//: ceActivityHasCertificateSaved(activity)
    
    // MARK: - URL and Folder Naming
    
   
   

    
    
    /// Method that does the work of finding the CeActivity stored in CoreData that the user is saving
    /// a CE certificate object for.
    /// - Parameter metaData: CertificateMetaData object, which has the ID for the CeActivity
    /// - Returns: the CeActivity entity matching the assignedObjectID property in CertificateMetaData
    func matchCertificateWithActivity(using metaData: CertificateMetadata) -> CeActivity? {
        let idToMatch = metaData.assignedObjectId
        let context = dataController.container.viewContext
        
        let activityFetch = CeActivity.fetchRequest()
        activityFetch.sortDescriptors = [NSSortDescriptor(key: "activityTitle", ascending: true)]
        activityFetch.predicate = NSPredicate(format: "activityID == %@", idToMatch as CVarArg)
        
        let fetchedActivities = (try? context.fetch(activityFetch)) ?? []
        guard fetchedActivities.count == 1 else { return nil }
        
        if let matchedActivity: CeActivity = fetchedActivities.first {
            return matchedActivity
        } else {
            return nil
        }
    }//: matchCertificatewithActivity
    
    // MARK: - INIT
    
    init(
        dataController: DataController,
        certBrain: CertificateBrain,
        coordManager: CertCoordinatorManager
    ) {
        self.dataController = dataController
        self.certBrain = certBrain
        self.coordManager = coordManager
    }//: INIT
    
}//: CLASS
