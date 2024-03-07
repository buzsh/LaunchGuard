//
//  DirectoryObserver.swift
//  LaunchGuard
//
//  Created by Justin Bush on 3/6/24.
//

import Foundation

class DirectoryObserver: ObservableObject {
  var directoryURL: URL
  var isRemovable: Bool
  private var dispatchSource: DispatchSourceFileSystemObject?
  private var fileDescriptor: Int32 = -1
  @Published var files: [URL] = []
  
  init(directoryURL: URL, isRemovable: Bool = true) {
    self.directoryURL = directoryURL
    self.isRemovable = isRemovable
    startObserving()
  }
  
  func startObserving() {
      stopObserving()
    
    fileDescriptor = open(directoryURL.path, O_EVTONLY)
    guard fileDescriptor != -1 else { return }
    
    let dispatchSource = DispatchSource.makeFileSystemObjectSource(
      fileDescriptor: fileDescriptor,
      eventMask: [.write, .delete],
      queue: DispatchQueue.global()
    )
    
    dispatchSource.setEventHandler { [weak self] in
      Task { [weak self] in
        await self?.updateFileList()
      }
    }
    
    dispatchSource.setCancelHandler { [weak self] in
      if let fd = self?.fileDescriptor, fd != -1 {
        close(fd)
        self?.fileDescriptor = -1
      }
    }
    
    dispatchSource.resume()
    self.dispatchSource = dispatchSource
    
    Task {
      await updateFileList()
    }
  }
  
  func stopObserving() {
    dispatchSource?.cancel()
    dispatchSource = nil
    if fileDescriptor != -1 {
      close(fileDescriptor)
      fileDescriptor = -1
    }
  }
  
  private func updateFileList() async {
    do {
      let fileURLs = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
      let filteredFileURLs = fileURLs.filter { $0.lastPathComponent != ".DS_Store" }
      await MainActor.run {
        self.files = filteredFileURLs.sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
      }
    } catch {
      Debug.log("Error updating file list for directory: \(directoryURL.lastPathComponent), error: \(error)")
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
