//
//  LaunchGuard.swift
//  LaunchGuard
//
//  Created by Justin Bush on 3/6/24.
//

import Foundation
import AppKit
import Combine

@MainActor
class LaunchGuard: ObservableObject {
  
  static let shared = LaunchGuard()
  private let workspace = NSWorkspace.shared
  private var cancellables: Set<AnyCancellable> = []
  
  @Published var runningApps: [String: String] = [:]
  
  init() {
    setupObservers()
    Task { await refreshRunningApps() }
  }
  
  private func setupObservers() {
    NotificationCenter.default.publisher(for: NSWorkspace.didLaunchApplicationNotification, object: nil)
      .sink { [weak self] _ in Task { await self?.refreshRunningApps() } }
      .store(in: &cancellables)
    
    NotificationCenter.default.publisher(for: NSWorkspace.didTerminateApplicationNotification, object: nil)
      .sink { [weak self] _ in Task { await self?.refreshRunningApps() } }
      .store(in: &cancellables)
  }
  
  private func refreshRunningApps() async {
    let apps = workspace.runningApplications
      .filter { $0.bundleIdentifier != nil }
      .reduce(into: [String: String]()) { result, app in
        let bundleID = app.bundleIdentifier!
        let name = app.localizedName ?? "Unknown"
        result[bundleID] = name
      }
    
    self.runningApps = apps
  }
  
}
