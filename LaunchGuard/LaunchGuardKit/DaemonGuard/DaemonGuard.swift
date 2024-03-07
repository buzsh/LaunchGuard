//
//  DaemonGuard.swift
//  LaunchGuard
//
//  Created by Justin Bush on 3/6/24.
//

import Foundation

extension Constants {
  static let persistedDirectoriesKey = "PersistedDirectories"
  
  static let rootLaunchAgentsDirUrl: URL = URL(fileURLWithPath: "/Library/LaunchAgents")
  static let rootLaunchDaemonsDirUrl: URL = URL(fileURLWithPath: "/Library/LaunchDaemons")
  static let homeLaunchAgentsDirUrl: URL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/LaunchAgents")
}

class DirectoryManager: ObservableObject {
  static let shared = DirectoryManager()
  
  @Published var directories: [DirectoryObserver] = []
  
  private init() {
    directories = [
      DirectoryObserver(directoryURL: Constants.rootLaunchAgentsDirUrl),
      DirectoryObserver(directoryURL: Constants.rootLaunchDaemonsDirUrl),
      DirectoryObserver(directoryURL: Constants.homeLaunchAgentsDirUrl)
    ]
    
    loadPersistedDirectories()
    startObserving()
  }
  
  func addDirectory(_ url: URL) {
    guard !directories.contains(where: { $0.directoryURL == url }) else { return }
    
    let newObserver = DirectoryObserver(directoryURL: url)
    directories.append(newObserver)
    newObserver.startObserving()
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
    guard let urls = UserDefaults.standard.object(forKey: Constants.persistedDirectoriesKey) as? [String],
          !urls.isEmpty else { return }
    
    let persistedUrls = urls.compactMap(URL.init(string:))
    let newUrls = persistedUrls.filter { url in
      !directories.contains { $0.directoryURL == url }
    }
    
    newUrls.forEach { addDirectory($0) }
  }
  
  func savePersistedDirectories() {
    let urls = directories.filter { $0.isRemovable }.map { $0.directoryURL.absoluteString }
    UserDefaults.standard.set(urls, forKey: Constants.persistedDirectoriesKey)
  }
}
