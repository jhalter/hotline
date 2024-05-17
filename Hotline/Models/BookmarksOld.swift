import SwiftUI

extension NSNotification {
  static let BookmarkAdded = Notification.Name("BookmarkAdded")
  static let BookmarkRemoved = Notification.Name("BookmarkRemoved")
}

enum BookmarkOldType: String, Codable {
  case tracker = "tracker"
  case server = "server"
}

struct BookmarkOld: Codable, Equatable {
  let type: BookmarkOldType
  let name: String
  let address: String
  let port: Int
  let login: String?
  let password: String?
  
  init(type: BookmarkOldType, name: String, address: String, port: Int = HotlinePorts.DefaultServerPort, login: String? = nil, password: String? = nil) {
    self.type = type
    self.name = name
    self.address = address
    self.port = port
    self.login = login
    self.password = password
  }
}

@Observable final class BookmarksOld {
  var bookmarks: [BookmarkOld]? = nil
  
  static let DefaultBookmarks: [BookmarkOld] = [
    BookmarkOld(type: .server, name: "System 7 Today", address: "hotline.system7today.com"),
    BookmarkOld(type: .server, name: "The Mobius Strip", address: "67.174.208.111"),
    BookmarkOld(type: .tracker, name: "Featured Servers", address: "hltracker.com"),
  ]
  
  init() {
    self.load()
  }
  
  func apply(_ newBookmarks: [BookmarkOld], save shouldSave: Bool = true) {
    self.bookmarks = newBookmarks
    if shouldSave {
      self.save()
    }
  }
  
  func load() {
    let jsonString: String? = DAKeychain.shared["Hotline Bookmarks"]
    let jsonData: Data? = jsonString?.data(using: .utf8, allowLossyConversion: false)
    
    let decoder = JSONDecoder()
    var decodedBookmarks = try? decoder.decode([BookmarkOld].self, from: jsonData ?? Data())
    if decodedBookmarks == nil || decodedBookmarks?.isEmpty == true {
      print("Bookmarks: using default bookmarks")
      decodedBookmarks = BookmarksOld.DefaultBookmarks
    }
    else {
      print("Bookmarks: using saved bookmarks")
    }
    
    self.bookmarks = [BookmarkOld](decodedBookmarks!)
  }
  
  func save() {
    var bookmarksToSave = self.bookmarks
    if bookmarksToSave == BookmarksOld.DefaultBookmarks {
      print("Bookmarks: skipping saving default bookmarks")
      bookmarksToSave = []
    }
    
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    if let jsonData = try? encoder.encode(bookmarksToSave) {
      if let jsonString = String(data: jsonData, encoding: .utf8) {
        DAKeychain.shared["Hotline Bookmarks"] = jsonString
      }
    }
  }
  
  // MARK: -
  
  func add(_ bookmark: BookmarkOld, save shouldSave: Bool = true) {
    self.bookmarks?.insert(bookmark, at: 0)
    
    if shouldSave {
      self.save()
    }
    
    DispatchQueue.main.async {
      NotificationCenter.default.post(name: NSNotification.BookmarkAdded, object: nil, userInfo: ["index": 0])
    }
  }
  
  func delete(_ bookmark: BookmarkOld, save shouldSave: Bool = true) -> Bool {
    if let i = self.bookmarks?.firstIndex(where: { b in b.address.lowercased() == bookmark.address.lowercased() && b.port == bookmark.port }) {
      self.bookmarks?.remove(at: i)
      
      if shouldSave {
        self.save()
      }
      
      DispatchQueue.main.async {
        NotificationCenter.default.post(name: NSNotification.BookmarkRemoved, object: nil, userInfo: ["index": i])
      }
      return true
    }
    
    return false
  }
  
  func update(_ bookmark: BookmarkOld, save shouldSave: Bool = true) -> Bool {
    if let i = self.bookmarks?.firstIndex(where: { b in b.address.lowercased() == bookmark.address.lowercased() && b.port == bookmark.port }) {
      self.bookmarks?[i] = bookmark
      if shouldSave {
        self.save()
      }
      return true
    }
    
    return false
  }
}
