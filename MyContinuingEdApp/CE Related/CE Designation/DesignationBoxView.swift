//
//  DesignationBoxView.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 8/26/25.
//

import SwiftUI

struct DesignationBoxView: View {
    // MARK: - PROPERTIES
    var designation: CeDesignation
    
   // Image showing whether the designation is currently selected
   var selectedYN: Bool
    
    // MARK: - BODY
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.black.opacity(0.7))
    
            HStack(alignment: .center) {
                VStack(alignment: .leading) {
                    Text(designation.ceDesignationAbbrev)
                        .font(.title2)
                        .foregroundStyle(.yellow)
                        .bold()
                    Text(designation.ceDesignationName)
                        .foregroundStyle(.gray)
                        .italic()
                        .lineLimit(1)
                }//: VSTACK
                .padding(.leading, 25)
                Spacer()
                
                if selectedYN {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.yellow)
                        .padding(.trailing, 10)
                }

            }//: HSTACK
            
        } //: ZSTACK
        .frame(height: 85)
        .frame(maxWidth: 350)
    }
}

// MARK: - PREVIEW
#Preview {
    DesignationBoxView(designation: .example, selectedYN: true)
}
