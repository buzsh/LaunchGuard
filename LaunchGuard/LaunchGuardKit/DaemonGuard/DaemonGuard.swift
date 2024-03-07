//
//  DaemonGuard.swift
//  LaunchGuard
//
//  Created by Justin Bush on 3/6/24.
//

import Foundation

extension Constants {
  static let persistedDirectoriesKey = "PersistedDirectories"
  
  static let rootLaunchAgentsDirUrl: URL = URL(string: "/Library/LaunchAgents")!
  static let rootLaunchDaemonsDirUrl: URL = URL(string: "/Library/LaunchDaemons")!
  static let homeLaunchAgentsDirUrl: URL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/LaunchAgents")
}

class DirectoryManager: ObservableObject {
  static let shared = DirectoryManager()
  
  @Published var directories: [DirectoryObserver] = [
    DirectoryObserver(directoryURL: Constants.rootLaunchAgentsDirUrl),
    DirectoryObserver(directoryURL: Constants.rootLaunchDaemonsDirUrl),
    DirectoryObserver(directoryURL: Constants.homeLaunchAgentsDirUrl)
  ]
  
  private let persistedDirectoriesKey = "PersistedDirectories"
  
  func addDirectory(_ url: URL) {
    guard !directories.contains(where: { $0.directoryURL == url }) else { return }
    
    let newObserver = DirectoryObserver(directoryURL: url)
    directories.append(newObserver)
    savePersistedDirectories()
  }
  
  func removeDirectory(_ url: URL) {
    guard let index = directories.firstIndex(where: { $0.directoryURL == url && $0.isRemovable }) else { return }
    
    directories[index].stopObserving()
    directories.remove(at: index)
    savePersistedDirectories()
  }
  
  func startObserving() {
    directories.forEach { $0.startObserving() }
  }
  
  func stopObserving() {
    directories.forEach { $0.stopObserving() }
  }
  
  func loadPersistedDirectories() {
    guard let urls = UserDefaults.standard.object(forKey: persistedDirectoriesKey) as? [String],
          !urls.isEmpty else { return }
    
    urls.compactMap { URL(string: $0) }.forEach { addDirectory($0) }
  }
  
  func savePersistedDirectories() {
    let urls = directories.filter { $0.isRemovable }.map { $0.directoryURL.absoluteString }
    UserDefaults.standard.set(urls, forKey: persistedDirectoriesKey)
  }
}
