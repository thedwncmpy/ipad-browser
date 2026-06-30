//
//  BrowserHomePage.swift
//  browser
//

import Foundation

enum BrowserHomePage {
    nonisolated(unsafe) static let url = URL(string: "browser://home")!
    nonisolated(unsafe) static let dateString = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }()

    nonisolated(unsafe) static let html = """
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
        }

        * { box-sizing: border-box; }

        body {
          margin: 0;
          min-height: 100vh;
          font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", sans-serif;
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
          text-align: center;
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
          margin: 22px auto 0;
          max-width: 560px;
          font-size: clamp(18px, 2vw, 21px);
          line-height: 1.5;
          color: var(--muted);
        }
      </style>
    </head>
    <body>
      <main class="shell">
        <section class="content">
          <p class="date">\(dateString)</p>
          <h1>browser</h1>
          <p>
            A blank starting point for favorites, quick links, and whatever comes next.
          </p>
        </section>
      </main>
    </body>
    </html>
    """
}
