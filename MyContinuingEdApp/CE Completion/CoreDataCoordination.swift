//
//  CoreDataCoordination.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/18/26.
//

import CoreData
import Foundation


final class CoreDataCoordination {
    // MARK: - PROPERTIES
    private let fileSystem = FileManager.default
    private weak var dataController: DataController?
    
    // MARK: - COMPUTED PROPERTIES
    
    
    // MARK: - METHODS
    
    func deleteLocalFile<T: RepresentsDeletableMediaFile>(
        for obj: T,
        fileClass: MediaClass
    ) async -> Result<Bool, FileIOError> {
        var basePathToUse: URL
        switch fileClass {
        case .certificate:
            basePathToUse = URL.localCertificatesFolder
        case .audioReflection:
            basePathToUse = URL.localAudioReflectionsFolder
        }//: SWITCH
        
        guard let fileURL: URL = obj.resolveURL(basePath: basePathToUse) else {
            return Result.failure(FileIOError.invalidURL)
        }//: GUARD
        
        do {
            try fileSystem.removeItem(at: fileURL)
            return Result.success(true)
        } catch {
            NSLog(">>> CoreDataCoordinaton error: deleteLocalFile")
            NSLog(">>> The removeItem method threw an error while trying to delete the file at: \(fileURL.path)")
            return Result.failure(FileIOError.unableToDelete)
        }//: DO-CATCH
    }//: deleteLocalFile()
    
    // MARK: - INIT
    
    init(dataController: DataController? = nil) {
        self.dataController = dataController
    }//: INIT
    
}//: CLASS
