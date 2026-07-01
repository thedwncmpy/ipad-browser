//
//  BrowserFavorite.swift
//  browser
//

import Foundation

struct BrowserFavorite: Codable, Identifiable, Equatable {
    let id: UUID
    var title: String
    var alias: String
    var urlString: String

    init(id: UUID = UUID(), title: String, alias: String, urlString: String) {
        self.id = id
        self.title = title
        self.alias = alias
        self.urlString = urlString
    }
}
