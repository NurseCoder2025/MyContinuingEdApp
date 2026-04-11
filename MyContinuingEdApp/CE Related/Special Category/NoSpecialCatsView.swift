//
//  NoSpecialCatsView.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/17/25.
//

// Purpose: To display text and a button whenever no special category objects exist in persistent
// storage, such as the first run of the app or user deletion of all objects.

import SwiftUI

struct NoSpecialCatsView: View {
    // MARK: - PROPERTIES
    @StateObject private var viewModel: ViewModel
    
    // Closure for triggering the sheet to add a new SpecialCategory
    var onPressAddSpecialCatButton: () -> Void
    
    // MARK: - BODY
    var body: some View {
        VStack {
            Image(systemName: "slash.circle")
                .font(.largeTitle)
            
            Group {
                Text("No Special CE Categories yet...")
                    .font(.title)
                
                
                Text("A special CE category is a subject like law or ethics that a credential issuer requires as part of regular continuing education requirements.  Usually, a portion of the total CE hour or units required must include so many in whatever special categories the governing body mandates. Depending on what type of credential you have and your governing body's requirements are, this may or may not apply to you.")
                    .font(.caption)
                    .multilineTextAlignment(.leading)
                    .padding(.bottom, 10)
                
                Text("Example: \n- 40 CE hours required total for renewal\n- 5 hours of ethics required\n- Total: 35 non-specified hours and 5 hours on ethics = 40 CE hours")
                    .font(.caption)
                    .multilineTextAlignment(.leading)
            } //: GROUP
            .padding()
            
            
            Text("If in doubt about whether you need to add a special CE category or not, please double-check with your licensing or credentialing body.")
                .font(.caption2)
                .multilineTextAlignment(.leading)
                .padding(20)
            
            Button {
                onPressAddSpecialCatButton()
            } label: {
                Label("Add Special Category", systemImage: "plus")
                    .font(.title)
            }
            .buttonStyle(.borderedProminent)
            
        }//: VSTACK
        
    }//: BODY
    
    // MARK: - INIT
    init(dataController: DataController, buttonPress: @escaping () -> Void) {
        self.onPressAddSpecialCatButton = buttonPress
        let viewModel = ViewModel(dataController: dataController)
        _viewModel = StateObject(wrappedValue: viewModel)
    }
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    NoSpecialCatsView(dataController: .preview, buttonPress: {})
}
