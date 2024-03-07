//
//  DirectoryObserver.swift
//  LaunchGuard
//
//  Created by Justin Bush on 3/6/24.
//

import Foundation
import SwiftUI
import Combine

class DirectoryObserver: ObservableObject {
  @Published var files: [String] = []
  
  private var directoryURL: URL
  private var observationTask: Task<Void, Never>?
  
  init(directoryURL: URL) {
    self.directoryURL = directoryURL
  }
  
  func startObserving() {
    stopObserving()
    observationTask = Task { [weak self] in
      while !Task.isCancelled {
        await self?.updateFileList()
        try? await Task.sleep(nanoseconds: 1_000_000_000) // Sleep for 1 second
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
      print("Error updating file list: \(error)")
    }
  }
  
  deinit {
    stopObserving()
  }
}
