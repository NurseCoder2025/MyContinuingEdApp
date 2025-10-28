//
//  SidebarTagsSectionViewModel.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 10/23/25.
//

import CoreData
import Foundation


extension SidebarTagsSectionView {
    
    class ViewModel: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
        // MARK: - PROPERTIES
        var dataController: DataController
        
        // Converting all fetched tags to Filter objects
        var convertedTagFilters: [Filter] {
            tags.map { tag in
                Filter(name: tag.tagTagName, icon: "tag", tag: tag)
            }
        }//: convertedTagFilters
        
        
        // MARK: - CORE DATA
        // All tags sorted by name
        private let tagsController: NSFetchedResultsController<Tag>
        @Published var tags: [Tag] = []
        
        // MARK: - FUNCTIONS
        
        func delete(_ offsets: IndexSet) {
            for offset in offsets {
                let item = tags[offset]
                dataController.delete(item)
            }
        } //: DELETE method
        
        /// This function is for deleting individual tag objects that the user created in SidebarView.  A single filter object with
        /// a tag property is to be passed into the function, which in turn will delete the filter IF there is a tag property.
        /// - Parameter filter: Filter object representing a user-created Tag that is to be deleted
        func deleteTag(_ filter: Filter) {
            guard let tag = filter.tag else {return}
            dataController.delete(tag)
            dataController.save()
        }
        
        /// Delegate method from the NSFetchResultsControllerDelegate that will notify the delegate when underlying data changes.  When a new
        /// tag object is added or existing one is deleted, then the change will trigger this function which will then call the tagsController to make
        /// another tag object fetch, assign all tag objects to the published tags property and then notify the UI of the change via the @Published
        /// wrapper.
        /// - Parameter controller: instance of a NSFetchedResultsController configured to fetch tag objects from the view context
        func controllerDidChangeContent(_ controller: NSFetchedResultsController<any NSFetchRequestResult>) {
            if let newTags = controller.fetchedObjects as? [Tag] {
                tags = newTags
            }
        }//: controllerDidChangeContent()
        
        // MARK: - INIT
        init(dataController: DataController) {
            self.dataController = dataController
            
            // Because the @FetchRequest is only used for SwiftUI and code has been moved into a ViewController
            // it is necessary to utilize the NSFetchedResultsController and delegate for fetching
            // tags and updating the fetch as objects change.
            let tagRequest = Tag.fetchRequest()
            tagRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Tag.tagName, ascending: true)]
            
            tagsController = NSFetchedResultsController(
                fetchRequest: tagRequest,
                managedObjectContext: dataController.container.viewContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            
            super.init( )
            tagsController.delegate = self
            
            do {
                try tagsController.performFetch( )
                tags = tagsController.fetchedObjects ?? []
            } catch {
                print("Failed to load any tag objects.")
            }
            
        }//: INIT
        
    }//: ViewModel
    
    
}//: SidebarTagsSectionView (ext)
