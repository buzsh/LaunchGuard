//
//  LaunchGuard.swift
//  LaunchGuard
//
//  Created by Justin Bush on 3/6/24.
//

import Foundation
import AppKit
import Combine

class AppProcess: Identifiable, ObservableObject {
  let id: UUID = UUID()
  let processID: Int32?
  let nsRunningApp: NSRunningApplication
  let name: String?
  let bundleID: String?
  let icon: NSImage?
  let bundleURL: URL?
  
  private var terminationObserver: NSKeyValueObservation?
  @Published var isTerminated: Bool
  
  init(nsRunningApp: NSRunningApplication) {
    self.processID = nsRunningApp.processIdentifier
    self.nsRunningApp = nsRunningApp
    self.name = nsRunningApp.localizedName
    self.icon = nsRunningApp.icon
    self.bundleID = nsRunningApp.bundleIdentifier
    self.bundleURL = nsRunningApp.bundleURL
    self.isTerminated = nsRunningApp.isTerminated
    
    terminationObserver = nsRunningApp.observe(\.isTerminated, options: [.new]) { [weak self] app, change in
      guard let self = self, let isTerminated = change.newValue else { return }
      self.isTerminated = isTerminated
    }
  }
  
  func quit() -> Bool {
    Debug.logTermination(for: self.name, id: self.bundleID)
    return nsRunningApp.terminate()
  }
  
  func forceQuit() -> Bool {
    Debug.logTermination(for: self.name, id: self.bundleID, withForce: true)
    return nsRunningApp.forceTerminate()
  }
  
  deinit {
    terminationObserver?.invalidate()
  }
}

extension Debug {
  static func logTermination(for appName: String?, id appBundleID: String?, withForce: Bool = false) {
    let name: String = appName ?? "nil"
    let bundleID: String = appBundleID ?? "nil"
    let terminationTypeString = withForce ? "force termination" : "termination"
    Debug.log("Sent \(terminationTypeString) request: \(name) (\(bundleID))")
  }
}


@MainActor
class LaunchGuard: ObservableObject {
  
  static let shared = LaunchGuard()
  private let workspace = NSWorkspace.shared
  private var cancellables: Set<AnyCancellable> = []
  
  @Published var apps: [AppProcess] = []
  @Published var terminatedApps: [AppProcess] = []
  
  init() {
    setupObservers()
    Task { await refreshRunningApps() }
  }
  
  private func setupObservers() {
    let workspaceNotificationCenter = NSWorkspace.shared.notificationCenter
    
    workspaceNotificationCenter.addObserver(forName: NSWorkspace.didLaunchApplicationNotification, object: nil, queue: .main) { [weak self] notification in
      if let nsRunningApp = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
        Task {
          await self?.appLaunched(nsRunningApp: nsRunningApp)
        }
      }
    }
  }
  
  private func appLaunched(nsRunningApp: NSRunningApplication?) async {
    guard let nsRunningApp = nsRunningApp else { return }
    let app = AppProcess(nsRunningApp: nsRunningApp)
    Debug.log("appLaunched: \(app.name ?? "nil") (\(app.bundleID ?? "nil"))")
    self.apps.append(app)
  }
  
  private func addAppProcess(_ appProcess: AppProcess) {
    let duplicate = apps.contains { existingApp in
      return existingApp.bundleID == appProcess.bundleID && existingApp.bundleURL == appProcess.bundleURL
    }
    guard !duplicate else { return }
    self.apps.append(appProcess)
  }
  
  func refreshRunningApps() async {
    apps = workspace.runningApplications.map { AppProcess(nsRunningApp: $0) }
  }
  
}
