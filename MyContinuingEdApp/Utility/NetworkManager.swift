//
//  NetworkManager.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/29/26.
//

import Foundation
import Network


/// Object designed to monitor whether the user's device likely has an active internet (network) connection and
/// report that state via the @Published property isConnected.
///
/// - Note: This object utilizes the singleton model, so must use the NetworkManager.shared because the init() method
/// for the class is set as a private init method.
///
///  The only action taken by this object is within the init (set as private) which sets the isConnected property based on
///  whether the path.status enum value is ".satisfied" or not.  If not, the isConnected property is set to false.  This task
///  is called by the NWPathMonitor's pathUpdateHandler after the monitor detects changes subsequent to being
///  started on the main thread (also within the private init).
final class NetworkManager: ObservableObject {
    // MARK: - PROPERTIES
    private let monitor = NWPathMonitor()
    
    @Published private(set) var isConnected: Bool = false
    
    // MARK: - SINGLETON
    static let shared = NetworkManager()
    
    // MARK: - METHODS
    
    // MARK: - INIT
    
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task{
                self?.isConnected = (path.status == .satisfied)
            }//: TASK
        }//: pathHupdateHandler
        
        monitor.start(queue: .main)
    }//: INIT
}//: CLASS
