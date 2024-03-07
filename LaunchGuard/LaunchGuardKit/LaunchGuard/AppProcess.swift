//
//  AppProcess.swift
//  LaunchGuard
//
//  Created by Justin Bush on 3/7/24.
//

import Foundation
import AppKit

class AppProcess: Identifiable, ObservableObject {
  let id: UUID = UUID()
  let processID: Int32?
  let nsRunningApp: NSRunningApplication
  let name: String?
  let bundleID: String?
  let icon: NSImage?
  let bundleURL: URL?
  
  @Published var isTerminated: Bool
  
  init(nsRunningApp: NSRunningApplication) {
    self.processID = nsRunningApp.processIdentifier
    self.nsRunningApp = nsRunningApp
    self.name = nsRunningApp.localizedName
    self.icon = nsRunningApp.icon
    self.bundleID = nsRunningApp.bundleIdentifier
    self.bundleURL = nsRunningApp.bundleURL
    self.isTerminated = nsRunningApp.isTerminated
  }
  
  func quit() -> Bool {
    Debug.logTermination(for: self.name, id: self.bundleID)
    return nsRunningApp.terminate()
  }
  
  func forceQuit() -> Bool {
    Debug.logTermination(for: self.name, id: self.bundleID, withForce: true)
    return nsRunningApp.forceTerminate()
  }
}

extension AppProcess: Equatable {
  static func == (lhs: AppProcess, rhs: AppProcess) -> Bool {
    //lhs.bundleID == rhs.bundleID && lhs.bundleURL == rhs.bundleURL
    lhs.id == rhs.id
  }
}
