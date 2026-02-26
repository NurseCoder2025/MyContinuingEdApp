//
//  CertificateActor.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 2/25/26.
//

import Foundation


/// Actor used for preventing data races when a class, such as CertificateBrain, needs to access
/// all of the CertificateCoordinator objects.
///
/// - Properties:
///     - allCoordinators: a private(set) variable for holding all CertificateCoordinator objects
///     - allCloudCoordinators: a private(set) variable for holding only those CertificateCoordinators
///     whose fileURL is an iCloud url
///
/// Use the various methods of this actor for inserting, removing, and otherwise setting the values for either
/// property as needed.
actor CertificateCoordinatorActor {
    // MARK: - MUTABLE PROPERTIES
    private(set) var allCoordinators: Set<CertificateCoordinator> = []
    private(set) var allCloudCoordinators: Set<CertificateCoordinator> = []
    
    // MARK: - SETTING VALUES
    
    // MARK: allCoordinators
    
        func insertCoordinator(_ coordinator: CertificateCoordinator) {
            allCoordinators.insert(coordinator)
        }//: insertCoordinator
        
        func removeCoordinator(_ coordinator: CertificateCoordinator) {
            allCoordinators.remove(coordinator)
        }//: removeCoordinator
        
        func setAllCoordinatorsValues(_ values: Set<CertificateCoordinator>) {
            allCoordinators = values
        }//: setAllCoordinatorsValues
    
        func removeAllCoordinators() { allCoordinators = [] }//: removeAllCoordinators()
    
    // MARK: CLOUD COORDINATORS
        
        func insertCloudCoordinator(_ coordinator: CertificateCoordinator) {
            allCloudCoordinators.insert(coordinator)
        }//: insertCloudCoordinator
    
        func removeCloudCoordinator(_ coordinator: CertificateCoordinator) {
            allCloudCoordinators.remove(coordinator)
        }//: removeAllCloudCoordinators
    
        func setAllCloudCoordinatorsValues(_ values: Set<CertificateCoordinator>) {
            allCloudCoordinators = values
        }//: setAllCloudCoordinatorsValues
    
        func removeAllCloudCoordinators() { allCloudCoordinators = [] }//: removeAllCloudCoordinators()

    
    // MARK: - RETRIEVING VALUES
    
    func getCoordinatorsForLocation(_ location: SaveLocation) -> Set<CertificateCoordinator> {
        
        allCoordinators.filter { coordinator in
            guard let metaData = coordinator.mediaMetadata as? CertificateMetadata else {return false}
            return metaData.whereSaved == location
        }//: filter
        
    }//: getCoordinatorsForLocation()
    
    func isAllCoordinatorsEmpty() -> Bool {
        allCoordinators.isEmpty
    }//: isAllCoordinatorsEmpty()
    
    func doesAllCoordinatorsHaveValues() -> Bool {
        allCoordinators.isNotEmpty
    }//: doeseAllCoordinatorsHaveValues()
    
    func isAllCloudCoordinatorsEmpty() -> Bool {
        allCloudCoordinators.isEmpty
    }//: isAllCloudCoordinatorsEmpty()
    
    
}//: CertificateActor
