//
//  RSCRowView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 1/7/26.
//

import SwiftUI

struct RSCRowView: View {
    // MARK: - PROPERTIES
    @ObservedObject var rcsItem: ReinstatementSpecialCat
    
    // MARK: - BODY
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }//: BODY
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    RSCRowView(rcsItem: .example)
}
