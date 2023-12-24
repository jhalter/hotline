import SwiftUI
import SwiftData

@main
struct Application: App {
  #if os(iOS)
  private var model = Hotline(trackerClient: HotlineTrackerClient(), client: HotlineClient())
  #endif
  
  private var preferences = Prefs()
  
  var body: some Scene {
    #if os(iOS)
    WindowGroup {
      TrackerView()
        .environment(model)
    }
    #elseif os(macOS)
    Window("Servers", id: "servers") {
      TrackerView()
        .frame(minWidth: 250, minHeight: 250)
        .toolbar {
          ToolbarItem(placement: .navigation) {
            Image("Hotline")
              .resizable()
              .renderingMode(.template)
              .scaledToFit()
              .foregroundColor(Color(hex: 0xE10000))
              .frame(width: 9)
          }
        }
    }
    .defaultSize(width: 700, height: 600)
    .defaultPosition(.center)
    
    WindowGroup(for: Server.self) { $server in
      if let s = server {
        ServerView(server: s)
          .frame(minWidth: 400, minHeight: 300)
          .environment(Hotline(trackerClient: HotlineTrackerClient(), client: HotlineClient()))
          .environment(preferences)
          .toolbar {
            ToolbarItem(placement: .navigation) {
              Image(systemName: "globe.americas.fill")
                .resizable()
                .scaledToFit()
//                .foregroundColor(.secondary)
                .frame(width: 22)
//                .fontWeight(.light)
//              Text("􀵲")
//                .font(.system(size: 22, weight: .ultraLight))
            }
          }
      }
    }
    .defaultSize(width: 700, height: 800)
    .defaultPosition(.center)
    
#if os(macOS)
    Settings {
      SettingsView()
        .environment(preferences)
    }
#endif

    #endif
  }
}
