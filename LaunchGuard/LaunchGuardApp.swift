//
//  LaunchGuardApp.swift
//  LaunchGuard
//
//  Created by Justin Bush on 3/6/24.
//

import SwiftUI

struct Constants {
  static let appName = "LaunchGuard"
}

@main
struct LaunchGuardApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  
  var body: some Scene {
    WindowGroup {
      ContentView()
        .frame(minWidth: 800, idealWidth: 900, minHeight: 500, idealHeight: 700)
    }
  }
}

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
  
  func applicationDidFinishLaunching(_ notification: Notification) {
    Debug.log("applicationDidFinishLaunching")
    _ = LaunchGuard.shared
    _ = DirectoryManager.shared
  }
  
  func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    Debug.log("applicationShouldTerminate")
    DirectoryManager.shared.stopObserving()
    return .terminateNow
  }
}
