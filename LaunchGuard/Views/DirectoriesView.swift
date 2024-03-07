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
  
  private var filteredDirectoryFiles: [(directoryURL: URL, files: [URL])] {
    var directoryFiles = [(directoryURL: URL, files: [URL])]()
    
    for directory in directoryManager.directories {
      let files: [URL] = directory.files.filter { file in
        searchText.isEmpty || file.lastPathComponent.localizedCaseInsensitiveContains(searchText)
      }
      
      if !files.isEmpty {
        directoryFiles.append((directoryURL: directory.directoryURL, files: files))
      }
    }
    
    return directoryFiles
  }
  
  private func refreshAllDirectories() {
    for directory in directoryManager.directories {
      Task {
        await directory.updateFileList()
      }
    }
  }
  
  var body: some View {
    Button("Manual Refresh") {
      refreshAllDirectories()
    }
    
    List {
      ForEach(filteredDirectoryFiles, id: \.directoryURL) { directory, files in
        Section(header: HStack {
          Text(directory.absoluteString)
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
            Text(file.lastPathComponent)
          }
        }
      }
    }
  }
}
  
  
  #Preview {
    DirectoriesView(searchText: .constant(""))
  }
