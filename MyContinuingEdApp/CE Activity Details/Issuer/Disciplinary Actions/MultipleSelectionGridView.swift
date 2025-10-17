//
//  MultipleSelectionGridView.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/15/25.
//

import SwiftUI

// Purpose: To display all of the DisciplinaryAction buttons in a grid view that the user can tap on


/// The MultipleSelectionGrivView struct creates a 2 row grid of fixed column width (44 pixels) for use
/// as a form row item within DisciplinaryActionItem.  It is designed to hold and display DisciplinaryActions.
///
/// This view also uses the DAButtonView for displaying each element within the grid.
struct MultipleSelectionGridView: View {
    let actions: [DisciplineAction]
    @Binding var selectedActions: [DisciplineAction]

    // Define grid layout: 2 rows, horizontal scroll
    let rows: [GridItem] = [
        GridItem(.fixed(44)),
        GridItem(.fixed(44))
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            LazyHGrid(rows: rows, spacing: 16) {
                ForEach(actions, id: \.self) { action in
                    DAButtonView(
                        title: action.rawValue.capitalized,
                        isSelected: selectedActions.contains(action)
                    ) {
                        if selectedActions.contains(action) {
                            selectedActions.removeAll { $0 == action }
                        } else {
                            selectedActions.append(action)
                        }
                    }
                    .frame(width: 150)
                }//: LOOP
            }//: LAZY H GRID
            .padding(.vertical, 8)
        }//: SCROLL VIEW
    }//: BODY
}//: STRUCT


