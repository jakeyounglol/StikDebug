import Foundation

struct Announcement: Identifiable, Codable {
    let id: Int
    let title: String
    let body: String
}

class AnnouncementManager {
    static func loadAnnouncements() -> [Announcement] {
        guard let url = Bundle.main.url(forResource: "announcements", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let announcements = try? JSONDecoder().decode([Announcement].self, from: data) else {
            return []
        }
        return announcements
    }
}
