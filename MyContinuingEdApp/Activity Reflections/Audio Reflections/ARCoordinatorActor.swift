//
//  ARCoordinatorActor.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 3/12/26.
//

import Foundation

actor ARCoordinatorActor {
    // MARK: - MUTABLE PROPERTIES
    private(set) var allCoordinators: Set<ARCoordinator> = []
    private(set) var allCloudCoordinators: Set<ARCoordinator> = []
    
    // MARK: - SETTING VALUES
    func insert(coordinator: ARCoordinator) {
        allCoordinators.insert(coordinator)
    }//: insert(coordinator)
    
    func removeCoordinator(_ coordinator: ARCoordinator) {
        allCoordinators.remove(coordinator)
    }//: removeCoordinator
    
    func setAllCoordinatorsValues(with values: Set<ARCoordinator>) {
        allCoordinators = values
    }//: setAllCoordinatorsValues(with)
    
    func removeAllCoordinators() { allCoordinators.removeAll() }//: removeAllCoordinators()
    
    // MARK: CLOUD COORDINATORS
    
    func insertCloudCoordinator(_ coordinator: ARCoordinator) {
        allCloudCoordinators.insert(coordinator)
    }//: insertCloudCoordinator
    
    func removeCloudCoordinator(_ coordinator: ARCoordinator) {
        allCloudCoordinators.remove(coordinator)
    }//: removeCloudCoordinator
    
    func setAllCloudCoordinators(with values: Set<ARCoordinator>) {
        allCloudCoordinators = values
    }//: setAllCloudCoordinators(with)
    
    func removeAllCloudCoordinators() { allCloudCoordinators.removeAll() }//: removeAllCloudCoordinators
    
    // MARK: - RETRIEVING VALUES
    
    func getCoordinatorsForLocation(_ location: SaveLocation) -> Set<ARCoordinator> {
        
        allCoordinators.filter {$0.whereSaved == location}
    }//: getCoordinatorsForLocation()
    
    
}//: ARCoordinatorActor
