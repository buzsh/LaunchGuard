//
//  LaunchGuardAppDelegate.swift
//  LaunchGuard
//
//  Created by Justin Bush on 3/7/24.
//

import Foundation
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
