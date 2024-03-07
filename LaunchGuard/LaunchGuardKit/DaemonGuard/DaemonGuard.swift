//
//  DaemonGuard.swift
//  LaunchGuard
//
//  Created by Justin Bush on 3/6/24.
//

import Foundation
import Combine

extension Constants {
  static let persistedDirectoriesKey = "PersistedDirectories"
  
  static let rootLaunchAgentsDirUrl: URL = URL(fileURLWithPath: "/Library/LaunchAgents")
  static let rootLaunchDaemonsDirUrl: URL = URL(fileURLWithPath: "/Library/LaunchDaemons")
  static let homeLaunchAgentsDirUrl: URL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/LaunchAgents")
}

class DirectoryManager: ObservableObject {
  static let shared = DirectoryManager()
  private var filesChangePublisher = PassthroughSubject<Void, Never>()
  private var cancellables: Set<AnyCancellable> = []
  
  @Published var directories: [DirectoryObserver] = []
  @Published var files: [URL] = []
  
  private init() {
    setupDirectories()
    observeDirectoriesChanges()
  }
  
  private func setupDirectories() {
    directories = [
      DirectoryObserver(directoryURL: Constants.rootLaunchAgentsDirUrl, isRemovable: false),
      DirectoryObserver(directoryURL: Constants.rootLaunchDaemonsDirUrl, isRemovable: false),
      DirectoryObserver(directoryURL: Constants.homeLaunchAgentsDirUrl, isRemovable: false)
    ]
    
    loadPersistedDirectories()
    startObserving()
  }
  
  private func observeDirectoriesChanges() {
    directories.forEach { observer in
      observer.$files
        .dropFirst()
        .sink { [weak self] _ in
          self?.filesChangePublisher.send()
        }
        .store(in: &cancellables)
    }
    
    filesChangePublisher
      .sink { [weak self] _ in
        self?.objectWillChange.send()
      }
      .store(in: &cancellables)
  }
  
  private func observeDirectories() {
    directories.forEach { directory in
      directory.$files
        .sink { [weak self] _ in
          self?.updateAggregatedFiles()
        }
        .store(in: &cancellables)
    }
  }
  
  private func updateAggregatedFiles() {
    Task {
      await MainActor.run {
        self.files = self.directories.flatMap { $0.files }
      }
    }
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
  
  func moveToTrash(fileURL: URL) async {
    guard let directoryIndex = directories.firstIndex(where: { fileURL.deletingLastPathComponent() == $0.directoryURL }) else {
      print("Directory for file not found")
      return
    }
    
    do {
      var resultingURL: NSURL?
      try FileManager.default.trashItem(at: fileURL, resultingItemURL: &resultingURL)
      await directories[directoryIndex].updateFileList()
      print("Moved to Trash: \(fileURL.lastPathComponent), New Location: \(String(describing: resultingURL))")
    } catch {
      print("Error moving file to trash: \(error)")
    }
  }
}
