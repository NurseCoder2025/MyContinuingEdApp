//
//  NoSpecialCatsViewModel.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 11/5/25.
//

import CoreData
import Foundation


extension NoSpecialCatsView {
    
    final class ViewModel: ObservableObject {
        // MARK: - PROPERTIES
        var dataController: DataController
        
        @Published var addedSpecialCategory: SpecialCategory?
        
        // MARK: - FUNCTIONS
        
        func addNewSpecialCategory() {
            let newSpecCat = dataController.createNewSpecialCategory()
            dataController.save()
            addedSpecialCategory = newSpecCat
        }//: addNewSpecialCategory
        
        // MARK: - INIT
        init(dataController: DataController) {
            self.dataController = dataController
        }
        
    }//: VIEW MODEL
    
    
}//: NoSpecialCatsView
