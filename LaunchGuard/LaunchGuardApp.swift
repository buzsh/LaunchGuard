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
  let directoryManager = DirectoryManager.shared
  
  func applicationDidFinishLaunching(_ notification: Notification) {
    Debug.log("applicationDidFinishLaunching")
    directoryManager.loadPersistedDirectories()
    directoryManager.startObserving()
  }
  
  func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    Debug.log("applicationShouldTerminate")
    directoryManager.stopObserving()
    return .terminateNow
  }
}
