//
//  DirectoryObserver.swift
//  LaunchGuard
//
//  Created by Justin Bush on 3/6/24.
//

import Foundation
import SwiftUI
import Combine

extension Constants {
  static let directoryRefereshIntervalInSeconds: UInt64 = 1
}

class DirectoryObserver: ObservableObject {
  @Published var files: [String] = []
  
  var directoryURL: URL
  private var observationTask: Task<Void, Never>?
  var isRemovable: Bool
  
  init(directoryURL: URL, isRemovable: Bool = true) {
    self.directoryURL = directoryURL
    self.isRemovable = isRemovable
  }
  
  func startObserving() {
    stopObserving()
    observationTask = Task { [weak self] in
      while !Task.isCancelled {
        await self?.updateFileList()
        try? await Task.sleep(nanoseconds: Constants.directoryRefereshIntervalInSeconds * 1_000_000_000)
      }
    }
  }
  
  func stopObserving() {
    observationTask?.cancel()
    observationTask = nil
  }
  
  private func updateFileList() async {
    do {
      let fileURLs = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
      DispatchQueue.main.async { [weak self] in
        self?.files = fileURLs.map { $0.lastPathComponent }.sorted()
      }
    } catch {
      Debug.log("Error updating file list: \(error)")
    }
  }
  
  deinit {
    stopObserving()
  }
}

extension DirectoryObserver: Equatable, Hashable {
  static func == (lhs: DirectoryObserver, rhs: DirectoryObserver) -> Bool {
    lhs.directoryURL == rhs.directoryURL
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(directoryURL)
  }
}
