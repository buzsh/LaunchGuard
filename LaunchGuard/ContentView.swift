//
//  ContentView.swift
//  LaunchGuard
//
//  Created by Justin Bush on 3/6/24.
//

import SwiftUI

struct ContentView: View {
  @ObservedObject var launchGuard = LaunchGuard.shared
  @State private var searchText = ""
  @State private var selectedApps: Set<UUID> = []
  
  @State private var columnVisibility = NavigationSplitViewVisibility.doubleColumn // .doubleColumn (hide by default)
  
  var body: some View {
    NavigationSplitView(columnVisibility: $columnVisibility) {
      Text("Sidebar!")
      
    } content: {
      Text("Main")
      
    } detail: {
      AppsTableView(selection: $selectedApps, searchText: searchText)
    }
    .toolbar {
      ToolbarItem {
        Button(action: refreshApps) {
          Label("Refresh", systemImage: "arrow.clockwise")
        }
      }
      
      ToolbarItem {
        Button(action: quitSelectedApps) {
          Label("Quit Selected", systemImage: "xmark.octagon")
        }
      }
      
      ToolbarItem(placement: .primaryAction) {
        TextField("Search name, bundle ID", text: $searchText)
          .textFieldStyle(.roundedBorder)
          //.frame(width: 300)
          .frame(minWidth: 100, maxWidth: 300)
      }
    }
  }
  func refreshApps() {
    Task {
      await launchGuard.refreshRunningApps()
    }
  }
  
  func quitSelectedApps() {
    for appID in selectedApps {
      if let appToQuit = launchGuard.apps.first(where: { $0.id == appID }) {
        let response = appToQuit.quit()
        Debug.log("Quit successful: \(response)")
      }
    }
  }
}

#Preview {
  ContentView()
}

struct AppsTableView: View {
  @ObservedObject var launchGuard = LaunchGuard.shared
  
  @Binding var selection: Set<UUID>
  let searchText: String
  
  var filteredApps: [AppProcess] {
    if searchText.isEmpty {
      return launchGuard.apps
    } else {
      return launchGuard.apps.filter {
        $0.name?.localizedCaseInsensitiveContains(searchText) ?? false ||
        $0.bundleID?.localizedCaseInsensitiveContains(searchText) ?? false
      }
    }
  }
  
  var body: some View {
    Table(filteredApps, selection: $selection) {
      TableColumn("Name") { app in
        NameColumn(app: app)
          .opacity(app.isTerminated ? 0.4 : 1.0)
      }
      TableColumn("Bundle ID") { app in
        BundleColumn(app: app)
          .opacity(app.isTerminated ? 0.4 : 1.0)
      }
    }
  }
}

struct NameColumn: View {
  let app: AppProcess
  
  var body: some View {
    HStack {
      IconImage(app: app)
        .padding(.trailing, 2)
      Text(app.name ?? "Unknown")
    }
    
  }
}

struct BundleColumn: View {
  let app: AppProcess
  
  var body: some View {
    Text(app.bundleID ?? "N/A")
  }
}

struct IconImage: View {
  let app: AppProcess
  
  var body: some View {
    if let icon = app.icon {
      Image(nsImage: icon)
        .resizable()
        .scaledToFit()
        .frame(width: 20, height: 20)
    } else {
      Image(systemName: "app.fill")
        .resizable()
        .scaledToFit()
        .frame(width: 20, height: 20)
    }
  }
}
