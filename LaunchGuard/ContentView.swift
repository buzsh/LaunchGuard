//
//  ContentView.swift
//  LaunchGuard
//
//  Created by Justin Bush on 3/6/24.
//

import SwiftUI

struct ContentView: View {
  @State private var searchText = ""
  @State private var columnVisibility = NavigationSplitViewVisibility.doubleColumn // .doubleColumn (hide by default)
  
  var body: some View {
    NavigationSplitView(columnVisibility: $columnVisibility) {
      Text("Sidebar!")
      
    } content: {
      Text("Main")
      
    } detail: {
      AppsTableView(searchText: searchText)
    }
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        TextField("Search name, bundle ID", text: $searchText)
          .textFieldStyle(.roundedBorder)
          .frame(minWidth: 100, maxWidth: 300)
      }
    }
  }
}

#Preview {
  ContentView()
}

struct AppsTableView: View {
  @ObservedObject var launchGuard = LaunchGuard.shared
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
    Table(filteredApps, selection: .constant(nil)) {
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
