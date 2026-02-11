//
//  CertificateController.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 2/10/26.
//

import CoreData
import Foundation


final class CertificateController: ObservableObject {
    // MARK: - PROPERTIES
    @Published private var allCertificates: [CECertificate] = []
    @Published private var credentialFolderURLs: Set<URL> = []
    @Published private var credentialRenewalFolderURLs: Set<URL> = []
    let masterListURL: URL = URL.applicationSupportDirectory.appending(path: "masterCertificateList.json", directoryHint: .notDirectory)
    var dataController: DataController
   
    
    
    // MARK: - COMPUTED PROPERTIES
    
    var currentStorageChoice: StorageToUse {
        dataController.certificateAudioStorage
    }//: currentStorageChoice
    
    // MARK: Top-Level Folder URLs
    var localCertsFolderURL: URL {
        return dataController.localStorage.appending(path: "Certificates", directoryHint: .isDirectory)
    }//: localCertsURL
    
    var cloudCertsFolderURL: URL? {
        if let existingURL = dataController.userCloudDriveURL {
            let customCloudURL = URL(
                filePath: "Documents/Certificates",
                directoryHint: .isDirectory,
                relativeTo: existingURL
            )
            return customCloudURL
        } else {
            return nil
        }
    }//: cloudCertsURL
    
    var unassignedCertsFolderURL: URL? {
        switch currentStorageChoice {
        case .local:
            let unassignedURL = URL(
                filePath: "Unassigned",
                directoryHint: .isDirectory,
                relativeTo: localCertsFolderURL
            )
            return unassignedURL
        case .cloud:
            if let cloudURL = cloudCertsFolderURL {
                let unassignedURL = URL(
                    filePath: "Unassigned",
                    directoryHint: .isDirectory,
                    relativeTo: cloudURL
                )
                return unassignedURL
            } else {
                return nil
            }
        }//: SWITCH
        
    }//: unassignedCertsFolderURL
    
    
    
    // MARK: - METHODS
    
    private func getMatchingCEActivity(for cert: CECertificate) -> CeActivity? {
        let context = dataController.container.viewContext
        let activityFetch = CeActivity.fetchRequest()
        activityFetch.sortDescriptors = [NSSortDescriptor(key: "activityTitle", ascending: true)]
        activityFetch.predicate = NSPredicate(format: "activityID == %@", cert.assignedCeId as CVarArg)
        let matchingCE: [CeActivity] = (try? context.fetch(activityFetch)) ?? []
        guard matchingCE.count == 1 else { return nil }
        
        return matchingCE[0]
    }//: matchCertWithCE
    
    private func save(cert: CECertificate) {
        if let matchingCe = getMatchingCEActivity(for: cert) {
            let ceAppliedTo = matchingCe.renewalsWithCredentials
            let credsWithRenewals = Set<Credential>(ceAppliedTo.keys)
            let assignedCreds = Set<Credential>(matchingCe.activityCredentials)
            let credsWithoutRenewals = assignedCreds.subtracting(credsWithRenewals)
            
            // Create folder for each credential activity was assigned to
            
            
        }//: IF LET
        
    }//: save()
    
    // Saving Certificates
    // Deleting Certificates
    // Moving local to iCloud
    
    func updateCertificateData() async {
        if dataController.iCloudAvailability.useLocalStorage {
            do {
                let localSystem = dataController.fileSystem
                let localContents = try localSystem.contentsOfDirectory(at: localCertsFolderURL, includingPropertiesForKeys: nil, options: [])
                for itemURL in localContents {
                    
                }
            } catch {
                
            }
        }
        
    }//: updateCertificateData
    
    
    private func createCredentialSubFolders() {
        let context = dataController.container.viewContext
        let credFetch = Credential.fetchRequest()
        credFetch.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        let allCredentials = (try? context.fetch(credFetch)) ?? []
        
        guard allCredentials.isNotEmpty else { return }
        
        switch currentStorageChoice {
        case .local:
            allCredentials.forEach { cred in
                let credFolderURL = URL(
                    filePath: cred.credentialName,
                    directoryHint: .isDirectory,
                    relativeTo: localCertsFolderURL
                )
                credentialFolderURLs.insert(credFolderURL)
                
                // Creating renewal period sub-folders for each
                // credential object
                let assignedRenewals = cred.allRenewals
                assignedRenewals.forEach { renewal in
                    let renewalFolderURL = URL(
                        filePath: renewal.renewalPeriodName,
                        directoryHint: .isDirectory,
                        relativeTo: credFolderURL
                    )
                    credentialRenewalFolderURLs.insert(renewalFolderURL)
                }//: forEach (assignedRenewals)
                
                // Creating a single folder that will hold CE activities
                // assigned to a Credential that does not have any Renewal
                // Period objects assigned to it yet (unlikely, but possible)
                let ungroupedCesFolderURL = URL(
                    filePath: "Ungrouped",
                    directoryHint: .isDirectory,
                    relativeTo: credFolderURL
                )
                credentialFolderURLs.insert(ungroupedCesFolderURL)
                
            }//: forEach (allCredentials)
        case .cloud:
            allCredentials.forEach { cred in
                if let cloudFolder = cloudCertsFolderURL {
                    let credFolderURL = URL(
                        filePath: cred.credentialName,
                        directoryHint: .isDirectory,
                        relativeTo: cloudFolder
                    )
                    credentialFolderURLs.insert(credFolderURL)
                    
                    // Creating renewal period sub-folders for each
                    // credential object
                    let assignedRenewals = cred.allRenewals
                    assignedRenewals.forEach { renewal in
                        let renewalFolderURL = URL(
                            filePath: renewal.renewalPeriodName,
                            directoryHint: .isDirectory,
                            relativeTo: credFolderURL
                        )
                        credentialRenewalFolderURLs.insert(renewalFolderURL)
                    }//: forEach (assignedRenewals)
                    
                    // Creating a single folder that will hold CE activities
                    // assigned to a Credential that does not have any Renewal
                    // Period objects assigned to it yet (unlikely, but possible)
                    let ungroupedCesFolderURL = URL(
                        filePath: "Ungrouped",
                        directoryHint: .isDirectory,
                        relativeTo: credFolderURL
                    )
                    credentialFolderURLs.insert(ungroupedCesFolderURL)
                    
                }//: IF LET
            }//: forEach
        }//: SWITCH
        
    }//: createCredentialSubFolders
    
    // MARK: - INIT
    
    init(dataController: DataController) {
        self.dataController = dataController
      
        if let listData = try? Data(contentsOf: masterListURL) {
            allCertificates = (try? JSONDecoder().decode([CECertificate].self, from: listData)) ?? []
        }
    }//: INIT
}//: CertificateController
