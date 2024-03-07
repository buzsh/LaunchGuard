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

extension Debug {
  static func logTermination(for appName: String?, id appBundleID: String?, withForce: Bool = false) {
    let name: String = appName ?? "nil"
    let bundleID: String = appBundleID ?? "nil"
    let terminationTypeString = withForce ? "forced termination" : "termination"
    Debug.log("Sent \(terminationTypeString) request: \(name) (\(bundleID))")
  }
}


@MainActor
class LaunchGuard: ObservableObject {
  
  static let shared = LaunchGuard()
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
    
    workspaceNotificationCenter.addObserver(forName: NSWorkspace.didTerminateApplicationNotification, object: nil, queue: .main) { [weak self] notification in
      if let nsRunningApp = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
        Task {
          await self?.appTerminated(nsRunningApp: nsRunningApp)
        }
      }
    }
  }
  
  private func appLaunched(nsRunningApp: NSRunningApplication?) async {
    guard let nsRunningApp = nsRunningApp else { return }
    let app = AppProcess(nsRunningApp: nsRunningApp)
    Debug.log("appLaunched: \(app.name ?? "nil") (\(app.bundleID ?? "nil"))")
    apps.append(app)
    terminatedApps.removeAll(where: { $0.bundleID == app.bundleID })
  }
  
  private func appTerminated(nsRunningApp: NSRunningApplication) async {
    let app = AppProcess(nsRunningApp: nsRunningApp)
    Debug.log("appTerminated: \(app.name ?? "nil") (\(app.bundleID ?? "nil"))")
    apps.removeAll(where: { $0.processID == app.processID })
    terminatedApps.append(app)
  }
  
  func refreshRunningApps() async {
    apps = NSWorkspace.shared.runningApplications.map { AppProcess(nsRunningApp: $0) }
  }
  
}
