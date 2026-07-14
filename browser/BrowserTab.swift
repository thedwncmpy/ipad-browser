//
//  BrowserTab.swift
//  browser
//

import Foundation

@MainActor
final class BrowserTab: Identifiable {
    let id = UUID()
    var currentURLString: String
    var currentPageURL: URL
    var pageTitle: String
    let navigationController = BrowserNavigationController()

    init(
        currentURLString: String = BrowserHomePage.url.absoluteString,
        currentPageURL: URL = BrowserHomePage.url,
        pageTitle: String = ""
    ) {
        self.currentURLString = currentURLString
        self.currentPageURL = currentPageURL
        self.pageTitle = pageTitle
    }
}
