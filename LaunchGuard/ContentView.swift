//
//  ContentView.swift
//  LaunchGuard
//
//  Created by Justin Bush on 3/6/24.
//

import SwiftUI

enum ViewManager: Hashable {
  case processes, daemons, split
}

struct ContentView: View {
  @ObservedObject var launchGuard = LaunchGuard.shared
  @State private var searchText = ""
  @State private var selectedApps: Set<UUID> = []
  @State private var selectedView: ViewManager = .processes
  @State private var columnVisibility = NavigationSplitViewVisibility.doubleColumn
  
  var body: some View {
    NavigationSplitView(columnVisibility: $columnVisibility) {
      Text("Sidebar!")
      
    } content: {
      Text("Rules")
      
    } detail: {
      detailView()
    }
    .toolbar {
      ToolbarItemGroup(placement: .navigation) {
        
      }
      
      ToolbarItemGroup(placement: .principal) {
        Picker("Options", selection: $selectedView) {
          Text("Processes").tag(ViewManager.processes)
          Text("Daemons").tag(ViewManager.daemons)
          Text("Split").tag(ViewManager.split)
        }
        .pickerStyle(SegmentedPickerStyle())
      }
      
      ToolbarItemGroup(placement: .automatic) {
        Spacer()
        Menu {
          Button(action: quitSelectedApps) {
            HStack {
              Image(systemName: "xmark.octagon")
              Text("Quit")
            }
          }
          .disabled(selectedApps.isEmpty)
          
          Button(action: forceQuitSelectedApps) {
            HStack {
              Image(systemName: "xmark.octagon.fill")
              Text("Force Quit")
            }
          }
          .disabled(selectedApps.isEmpty)
          
        } label: {
          Label("Quit...", systemImage: "xmark.octagon")
        }
        TextField("Search name, bundle ID", text: $searchText)
          .textFieldStyle(.roundedBorder)
          .frame(width: 165)
      }
    }
  }
  
  @ViewBuilder
  private func detailView() -> some View {
    switch selectedView {
    case .processes:
      AppsTableView(selection: $selectedApps, searchText: searchText)
    case .daemons:
      DirectoriesView()
    case .split:
      VSplitView {
        DirectoriesView()
        AppsTableView(selection: $selectedApps, searchText: searchText)
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
        _ = appToQuit.quit()
      }
    }
    refreshApps()
  }
  func forceQuitSelectedApps() {
    for appID in selectedApps {
      if let appToQuit = launchGuard.apps.first(where: { $0.id == appID }) {
        _ = appToQuit.forceQuit()
      }
    }
    refreshApps()
  }
}

#Preview {
  ContentView()
    .frame(width: 800, height: 600)
}

struct AppsTableView: View {
  @ObservedObject var launchGuard = LaunchGuard.shared
  
  @Binding var selection: Set<UUID>
  let searchText: String
  
  var filteredApps: [AppProcess] {
    let allApps = launchGuard.apps + launchGuard.terminatedApps
    if searchText.isEmpty {
      return allApps
    } else {
      return allApps.filter {
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
