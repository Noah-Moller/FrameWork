//
//  CompletionListView.swift
//  FrameWork
//
//  Created by Noah Moller on 11/2/24.
//

import SwiftUI

struct CompletionListView: View {
    let completions: [String]
    var selectCompletion: (String) -> Void

    var body: some View {
        List(completions, id: \.self) { completion in
            Text(completion)
                .onTapGesture {
                    selectCompletion(completion)
                }
        }
        .frame(width: 200, height: 150)
    }
}

