//
//  SpecialCatRowView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 11/5/25.
//

// Purpose: Create a reusable row view for the SpecialCECatsManagementSheet and other potential
// views in the app.

import SwiftUI

struct SpecialCatRowView: View {
    // MARK: - PROPERTIES
       
    let specialCat: SpecialCategory
    let credential: Credential?
    let activity: CeActivity?
    
    // Closures for editing, deleting, and tapping
    var onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    // MARK: - BODY
    var body: some View {
        HStack {
            Text(specialCat.specialName)
            Spacer()
            if categoryIsSelected() {
                Image(systemName: "checkmark")
            }
        } //: HSTACK (ROW)
        .contentShape(Rectangle())
        .accessibilityElement()
        .accessibilityLabel(Text("\(specialCat.specialName)"))
        .accessibilityHint(Text("Tap to assign or unassign category. Currently, this category is \(categoryIsSelected() ? "assigned" : "not assigned") ."))
        // MARK: - ON TAP
        .onTapGesture {
            onTap()
        }
        // MARK: - SWIPE
        .swipeActions {
            // EDIT button
            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            // DELETE button
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        
    }//: BODY
     // MARK: - FUNCTIONS
    /// PRIVATE method used to customize the accessibility hint for SpecialCatRowView, using any passed in CeActivity or Credential objects to
    /// tell the user whether the object has been selected or not.  Also used to either show or hide the selection image indicator.
    /// - Returns: Boolean reflecting whether the SpecialCategory object has been assigned to either the CeActivity or Credential
    private func categoryIsSelected() -> Bool {
        if let passedInCredential = credential {
            if let specialCats = passedInCredential.specialCats as? Set<SpecialCategory>, specialCats.contains(specialCat) {
                return true
            }
        } else if let passedInActivity = activity {
            if passedInActivity.specialCat == specialCat {
                return true
            }
        } else {
            return false
        }
        return false
    }//: categoryIsSelected()
    
    // MARK: - INIT
    init(specialCat: SpecialCategory, credential: Credential?, activity: CeActivity?, onTap: @escaping () -> Void, onEdit: @escaping () -> Void, onDelete: @escaping () -> Void) {
        self.specialCat = specialCat
        self.credential = credential
        self.activity = activity
        self.onTap = onTap
        self.onEdit = onEdit
        self.onDelete = onDelete
    }
    
}//: STRUCT


// MARK: - PREVIEW
#Preview {
    SpecialCatRowView(specialCat: .example, credential: nil, activity: nil, onTap: {}, onEdit: {}, onDelete: {})
}
