//
//  DirectoriesView.swift
//  LaunchGuard
//
//  Created by Justin Bush on 3/6/24.
//

import SwiftUI

struct DirectoriesView: View {
  @ObservedObject private var directoryManager = DirectoryManager.shared
  @Binding var searchText: String
  
  var body: some View {
    List {
      ForEach(directoryManager.filteredFiles(searchText: searchText), id: \.directoryURL) { directory, files in
        Section(header: HStack {
          Text(directory.path)
            .font(.system(size: 11, weight: .medium, design: .monospaced))
          Spacer()
          Button(action: {
            NSWorkspace.shared.open(directory)
          }) {
            Image(systemName: "folder")
          }
          .buttonStyle(PlainButtonStyle())
        }) {
          ForEach(files, id: \.self) { file in
            Text(file)
          }
        }
      }
    }
  }
}


#Preview {
  DirectoriesView(searchText: .constant(""))
}

extension DirectoryManager {
  func filteredFiles(searchText: String) -> [(directoryURL: URL, files: [String])] {
    let filtered = directories.map { observer -> (directoryURL: URL, files: [String]) in
      if searchText.isEmpty {
        return (observer.directoryURL, observer.files)
      } else {
        let files = observer.files.filter { $0.localizedCaseInsensitiveContains(searchText) }
        return (observer.directoryURL, files)
      }
    }.filter { !$0.files.isEmpty || searchText.isEmpty }
    
    return filtered
  }
}

