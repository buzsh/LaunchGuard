//
//  DirectoriesView.swift
//  LaunchGuard
//
//  Created by Justin Bush on 3/6/24.
//

import SwiftUI

struct DirectoriesView: View {
  @StateObject private var directoryObserver1 = DirectoryObserver(directoryURL: URL(string: "/Library/LaunchAgents")!)
  @StateObject private var directoryObserver2 = DirectoryObserver(directoryURL: URL(string: "/Library/LaunchDaemons")!)
  @StateObject private var directoryObserver3: DirectoryObserver = {
      let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
      let launchAgentsPath = homeDirectory.appendingPathComponent("Library/LaunchAgents")
      return DirectoryObserver(directoryURL: launchAgentsPath)
  }()
  
  var body: some View {
    List {
      Section(header: Text("/Library/LaunchAgents").font(.system(size: 11, weight: .medium, design: .monospaced))) {
        ForEach(directoryObserver1.files, id: \.self) { file in
          Text(file)
        }
      }
      Section(header: Text("/Library/LaunchDaemons").font(.system(size: 11, weight: .medium, design: .monospaced))) {
        ForEach(directoryObserver2.files, id: \.self) { file in
          Text(file)
        }
      }
      Section(header: Text("~/Library/LaunchAgents").font(.system(size: 11, weight: .medium, design: .monospaced))) {
        ForEach(directoryObserver3.files, id: \.self) { file in
          Text(file)
        }
      }
    }
    .onAppear {
      directoryObserver1.startObserving()
      directoryObserver2.startObserving()
      directoryObserver3.startObserving()
    }
    .onDisappear {
      directoryObserver1.stopObserving()
      directoryObserver2.stopObserving()
      directoryObserver3.stopObserving()
    }
  }
}

#Preview {
  DirectoriesView()
}
