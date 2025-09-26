//
//  RenewalPeriodEditingView.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/23/25.
//

// Purpose: Draw the controls for the user to be able to create and edit RenewalPeriod objects

import SwiftUI

struct RenewalTopEditingView: View {
    // MARK: - PROPERTIES
    let credential: Credential
    
    // Bindings to parent view (RenewalPeriodView)
    @Binding var reinstatingYN: Bool
    @Binding var reinstateHours: Double
    
    // MARK: - BODY
    var body: some View {
        // MARK: Number & Currency Formatters
        var generalDecimal: NumberFormatter {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 2
            return formatter
        }
        
        Group {
            VStack {
                // Name of specified credential
                HStack {
                    Text("For Credential:")
                    Text(credential.credentialName)
                }//: HSTACK
                
                
                
                // Reinstatement info
                Toggle(isOn: $reinstatingYN) {
                    Text("Reinstating Credential?")
                }
                
                if reinstatingYN {
                    TextField("CE Hours Needed:", value: $reinstateHours, formatter: generalDecimal)
                }
            }//: VSTACK
            .padding()
            
        }//: GROUP
    }
}

// MARK: - PREVIEW
#Preview {
    RenewalTopEditingView(credential: .example, reinstatingYN: .constant(false), reinstateHours: .constant(1.0))
}
