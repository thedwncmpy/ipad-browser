//
//  BrowserHomePage.swift
//  browser
//

import Foundation

enum BrowserHomePage {
    nonisolated(unsafe) static let url = URL(string: "browser://home")!
    nonisolated(unsafe) static let favoritesDefaultsKey = "browser.favorites"

    static func html() -> String {
        let favoritesMarkup = favoriteCardsMarkup()

        return """
        <!doctype html>
        <html lang="en">
        <head>
          <meta charset="utf-8" />
          <meta name="viewport" content="width=device-width, initial-scale=1" />
          <title>browser</title>
          <style>
            :root {
              color-scheme: dark;
              --bg: #000000;
              --text: rgba(255, 255, 255, 0.96);
              --muted: rgba(255, 255, 255, 0.58);
              --soft: rgba(255, 255, 255, 0.08);
              --soft-border: rgba(255, 255, 255, 0.14);
            }

            * { box-sizing: border-box; }

            body {
              margin: 0;
              min-height: 100vh;
              font-family: "LilexNFM-Regular", monospace;
              color: var(--text);
              background: var(--bg);
            }

            .shell {
              min-height: 100vh;
              display: flex;
              align-items: center;
              justify-content: center;
              padding: 32px;
            }

            .content {
              width: min(720px, 100%);
              text-align: left;
            }

            .time {
              margin: 0 0 8px;
              font-size: 24px;
              letter-spacing: 0.04em;
              color: var(--text);
            }

            .date {
              margin: 0 0 18px;
              font-size: 14px;
              letter-spacing: 0.18em;
              text-transform: uppercase;
              color: var(--muted);
            }

            h1 {
              margin: 0;
              font-size: clamp(54px, 10vw, 108px);
              line-height: 0.9;
              letter-spacing: -0.05em;
            }

            p {
              margin: 22px 0 0;
              max-width: 560px;
              font-size: clamp(18px, 2vw, 21px);
              line-height: 1.5;
              color: var(--muted);
            }

            .favorites {
              margin: 40px 0 0;
              display: grid;
              grid-template-columns: repeat(4, minmax(0, 1fr));
              gap: 14px;
              max-width: 560px;
            }

            .favorite {
              display: flex;
              flex-direction: column;
              align-items: center;
              justify-content: center;
              gap: 10px;
              aspect-ratio: 1 / 1;
              min-height: 0;
              padding: 14px 10px 12px;
              text-decoration: none;
              color: var(--text);
              border-radius: 18px;
              background: var(--soft);
              border: 1px solid var(--soft-border);
              outline: none;
              transition: background 120ms ease, border-color 120ms ease, box-shadow 120ms ease, transform 120ms ease;
            }

            .favorite:hover {
              background: rgba(255, 255, 255, 0.12);
              border-color: rgba(255, 255, 255, 0.22);
              transform: translateY(-1px);
            }

            .favorite.is-selected {
              background: rgba(255, 255, 255, 0.16);
              border-color: rgba(255, 255, 255, 0.52);
              box-shadow: 0 0 0 2px rgba(255, 255, 255, 0.18);
              transform: translateY(-1px);
            }

            .favorite-icon {
              width: 30px;
              height: 30px;
              border-radius: 8px;
              overflow: hidden;
              display: block;
              background: rgba(255, 255, 255, 0.06);
            }

            .favorite-icon img {
              width: 100%;
              height: 100%;
              display: block;
            }

            .favorite-label {
              font-size: 13px;
              letter-spacing: 0.04em;
              color: var(--muted);
              word-break: break-word;
              text-align: center;
            }

            @media (max-width: 640px) {
              .favorites {
                grid-template-columns: repeat(2, minmax(0, 1fr));
              }
            }
          </style>
        </head>
        <body>
          <main class="shell">
            <section class="content">
              <p class="time" id="time"></p>
              <p class="date" id="date"></p>
              <h1>browser</h1>
              \(favoritesMarkup)
            </section>
          </main>
          <script>
            const timeElement = document.getElementById('time');
            const dateElement = document.getElementById('date');

            function updateClock() {
              const now = new Date();
              timeElement.textContent = now.toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' });
              dateElement.textContent = now
                .toLocaleDateString([], { weekday: 'long', month: 'long', day: 'numeric' })
                .toUpperCase();
            }

            updateClock();
            setInterval(updateClock, 1000);

            const favoriteGrid = document.querySelector('.favorites');
            const favorites = Array.from(document.querySelectorAll('.favorite'));
            let selectedFavoriteIndex = favorites.length > 0 ? 0 : -1;

            function favoriteColumnCount() {
              if (!favoriteGrid) return 1;
              const columns = getComputedStyle(favoriteGrid).gridTemplateColumns;
              return Math.max(columns.split(' ').filter(Boolean).length, 1);
            }

            function selectFavorite(index, shouldFocus = false) {
              if (favorites.length === 0) return;
              selectedFavoriteIndex = Math.max(0, Math.min(index, favorites.length - 1));

              favorites.forEach((favorite, favoriteIndex) => {
                favorite.classList.toggle('is-selected', favoriteIndex === selectedFavoriteIndex);
                favorite.setAttribute('tabindex', favoriteIndex === selectedFavoriteIndex ? '0' : '-1');
              });

              if (shouldFocus) {
                favorites[selectedFavoriteIndex].focus({ preventScroll: true });
              }
            }

            function moveFavoriteSelection(offset) {
              if (selectedFavoriteIndex === -1) return;
              selectFavorite(selectedFavoriteIndex + offset, true);
            }

            window.__browserFocusSelectedFavorite = function() {
              selectFavorite(selectedFavoriteIndex, true);
            };

            favorites.forEach((favorite, index) => {
              favorite.addEventListener('mouseenter', () => selectFavorite(index, false));
              favorite.addEventListener('focus', () => selectFavorite(index, false));
            });

            document.addEventListener('keydown', (event) => {
              if (window.__browserSidebarNavigationEnabled === true) {
                return;
              }

              if (event.metaKey || event.ctrlKey || event.altKey || event.shiftKey || selectedFavoriteIndex === -1) {
                return;
              }

              const columns = favoriteColumnCount();

              switch (event.key) {
              case 'ArrowLeft':
              case 'h':
                event.preventDefault();
                moveFavoriteSelection(-1);
                break;
              case 'ArrowRight':
              case 'l':
                event.preventDefault();
                moveFavoriteSelection(1);
                break;
              case 'ArrowUp':
              case 'k':
                event.preventDefault();
                moveFavoriteSelection(-columns);
                break;
              case 'ArrowDown':
              case 'j':
                event.preventDefault();
                moveFavoriteSelection(columns);
                break;
              case 'Enter':
              case ' ':
                event.preventDefault();
                favorites[selectedFavoriteIndex].click();
                break;
              default:
                break;
              }
            });

            requestAnimationFrame(() => selectFavorite(selectedFavoriteIndex, true));
          </script>
        </body>
        </html>
        """
    }

    private static func favoriteCardsMarkup() -> String {
        let favorites = loadFavorites()
        guard !favorites.isEmpty else { return "" }

        let cards = favorites.map { favorite in
            let escapedAlias = htmlEscaped(favorite.alias)
            let escapedURL = htmlEscaped(browserOpenURLString(for: favorite.urlString))
            let faviconURL = htmlEscaped(faviconURLString(for: favorite.urlString))

            return """
            <a class="favorite" href="\(escapedURL)">
              <span class="favorite-icon">
                <img src="\(faviconURL)" alt="" />
              </span>
              <span class="favorite-label">\(escapedAlias)</span>
            </a>
            """
        }.joined()

        return #"<div class="favorites">\#(cards)</div>"#
    }

    private static func loadFavorites() -> [BrowserFavorite] {
        guard let data = UserDefaults.standard.data(forKey: favoritesDefaultsKey) else {
            return []
        }

        return (try? JSONDecoder().decode([BrowserFavorite].self, from: data)) ?? []
    }

    private static func faviconURLString(for urlString: String) -> String {
        guard let url = URL(string: urlString), let host = url.host() else {
            return ""
        }

        return "https://www.google.com/s2/favicons?domain=\(host)&sz=64"
    }

    private static func browserOpenURLString(for urlString: String) -> String {
        var components = URLComponents()
        components.scheme = "browser"
        components.host = "open"
        components.queryItems = [URLQueryItem(name: "url", value: urlString)]
        return components.url?.absoluteString ?? urlString
    }

    private static func htmlEscaped(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}
