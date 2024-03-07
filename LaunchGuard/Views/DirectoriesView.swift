//
//  DirectoriesView.swift
//  LaunchGuard
//
//  Created by Justin Bush on 3/6/24.
//

import SwiftUI

struct DirectoriesView: View {
  @ObservedObject private var directoryManager = DirectoryManager.shared
  
  var body: some View {
    List {
      ForEach(directoryManager.directories, id: \.self) { directoryObserver in
        Section(header: Text(directoryObserver.directoryURL.path)
          .font(.system(size: 11, weight: .medium, design: .monospaced))) {
            ForEach(directoryObserver.files, id: \.self) { file in
              Text(file)
            }
          }
      }
    }
  }
}

#Preview {
  DirectoriesView()
}
