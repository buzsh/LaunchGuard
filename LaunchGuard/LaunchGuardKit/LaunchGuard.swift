//
//  LaunchGuard.swift
//  LaunchGuard
//
//  Created by Justin Bush on 3/6/24.
//

import Foundation
import AppKit
import Combine

class AppProcess: Identifiable {
  let id: Int32
  let nsRunningApp: NSRunningApplication
  let name: String?
  let bundleID: String?
  let bundleURL: URL?
  
  init(nsRunningApp: NSRunningApplication) {
    self.id = nsRunningApp.processIdentifier
    self.nsRunningApp = nsRunningApp
    self.name = nsRunningApp.localizedName
    self.bundleID = nsRunningApp.bundleIdentifier
    self.bundleURL = nsRunningApp.bundleURL
  }
  
  func quit() -> Bool {
    nsRunningApp.terminate()
  }
  
  func forceQuit() -> Bool {
    nsRunningApp.forceTerminate()
  }
}

@MainActor
class LaunchGuard: ObservableObject {
  
  static let shared = LaunchGuard()
  private let workspace = NSWorkspace.shared
  private var cancellables: Set<AnyCancellable> = []
  
  @Published var runningApps: [AppProcess] = []
  @Published var terminatedApps: [AppProcess] = []
  
  init() {
    setupObservers()
    Task { await refreshRunningApps() }
  }
  
  private func setupObservers() {
    NotificationCenter.default.publisher(for: NSWorkspace.didLaunchApplicationNotification, object: nil)
      .sink { [weak self] notification in Task { await self?.appLaunched(notification: notification) } }
      .store(in: &cancellables)
    
    NotificationCenter.default.publisher(for: NSWorkspace.didTerminateApplicationNotification, object: nil)
      .sink { [weak self] notification in Task { await self?.appTerminated(notification: notification) } }
      .store(in: &cancellables)
  }
  
  private func appLaunched(notification: Notification) async {
    guard let nsRunningApp = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
    let app = AppProcess(nsRunningApp: nsRunningApp)
    await MainActor.run {
      self.addAppProcess(app)
    }
  }
  
  private func appTerminated(notification: Notification) async {
    guard let nsRunningApp = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
    if let index = runningApps.firstIndex(where: { $0.id == nsRunningApp.processIdentifier }) {
      await MainActor.run {
        let terminatedApp = runningApps.remove(at: index)
        self.terminatedApps.append(terminatedApp)
      }
    }
  }
  
  private func addAppProcess(_ appProcess: AppProcess) {
    let duplicate = runningApps.contains { existingApp in
      return existingApp.bundleID == appProcess.bundleID && existingApp.bundleURL == appProcess.bundleURL
    }
    guard !duplicate else { return }
    self.runningApps.append(appProcess)
  }
  
  private func refreshRunningApps() async {
    runningApps = workspace.runningApplications.map { AppProcess(nsRunningApp: $0) }
  }
  
}
