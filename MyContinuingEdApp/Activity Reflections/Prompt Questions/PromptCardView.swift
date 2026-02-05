//
//  PromptCardView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 1/28/26.
//

// This view is to show a single reflection prompt question

import SwiftUI

struct PromptCardView: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    @ObservedObject var prompt: ReflectionPrompt
    
    // MARK: - BODY
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button {
                    prompt.favoriteYN.toggle()
                } label: {
                    Image(systemName: prompt.favoriteYN ? "star.fill" : "star")
                        .foregroundStyle(.yellow)
                }//: BUTTON
                .accessibilityLabel(Text(prompt.favoriteYN ? "Tap to Add Prompt to Favorites" : "Prompt Marked as Favorite"))
                .padding(.trailing, 25)
            }//: HSTACK
            .padding(.top, 15)
            Spacer()
            Text(prompt.promptQuestion)
                .font(.headline)
                .multilineTextAlignment(.leading)
                .padding()
               
        }//: VSTACK
        .frame(width: 250, height: 175, alignment: .bottomLeading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .foregroundStyle(.white)
                .shadow(color: Color.black.opacity(0.3), radius: 5)
        )
        // MARK: - ON RECEIVE
        .onReceive(prompt.objectWillChange) { _ in
            dataController.queueSave()
        }//: ON RECIEVE
        
    }//: BODY
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    PromptCardView(prompt: .longExample)
        .environmentObject(DataController(inMemory: true))
}
