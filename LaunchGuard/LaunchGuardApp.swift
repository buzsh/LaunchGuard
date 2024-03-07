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
