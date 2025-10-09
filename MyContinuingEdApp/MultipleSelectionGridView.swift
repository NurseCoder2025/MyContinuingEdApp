//
//  MultipleSelectionGridView.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/15/25.
//

import SwiftUI

// Purpose: To display all of the DisciplinaryAction buttons in a grid view that the user can tap on


// MARK: - GRID ITEM
struct DAButtonView: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(.translucentGreyGradient) // TODO: Update background color based on selection
                .frame(width: 150, height: 44)
            Button(action: action) {
                HStack {
                    Text(title)
                        .font(.caption)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark")
                            .padding(.trailing, 10)
                    }
                }//: HSTACK
            }//: BUTTON
            .foregroundColor(.primary)
            .padding(.leading, 10)
        }//: ZSTACK
    }
}



// MARK: - GRID VIEW

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
                }
            }
            .padding(.vertical, 8)
        }
    }
}


