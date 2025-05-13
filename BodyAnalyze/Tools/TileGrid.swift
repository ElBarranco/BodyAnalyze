//
//  TileGrid.swift
//  BodyAnalyze
//
//  Created by Lionel Barranco on 05/05/2025.
//

import SwiftUI

enum TileSpan {
    case half
    case full
}

struct Tile<Content: View>: View {
    let span: TileSpan
    let content: Content
    var backgroundColor: Color?

    init(
        span: TileSpan = .half,
        backgroundColor: Color? = Color(.secondarySystemBackground),
        @ViewBuilder content: () -> Content
    ) {
        self.span = span
        self.backgroundColor = backgroundColor
        self.content = content()
    }

    var body: some View {
        VStack {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(backgroundColor.map { AnyView($0.cornerRadius(12)) } ?? AnyView(EmptyView()))
        .layoutPriority(1)
    }

    func wrapped() -> TileWrapper {
        TileWrapper(span: self.span, view: AnyView(self))
    }
}

struct TileWrapper {
    let span: TileSpan
    let view: AnyView
}

@resultBuilder
struct TileGridBuilder {
    static func buildBlock(_ components: TileWrapper...) -> [TileWrapper] {
        return components
    }
}

struct TileGrid: View {
    private let tiles: [TileWrapper]

    init(@TileGridBuilder content: () -> [TileWrapper]) {
        self.tiles = content()
    }

    var body: some View {
        VStack(spacing: 16) {
            ForEach(Array(buildGrid().enumerated()), id: \.offset) { _, row in
                row
            }
        }
        .padding(.horizontal, 16)
    }

    private func buildGrid() -> [AnyView] {
        var views: [AnyView] = []
        var index = 0

        while index < tiles.count {
            let tile = tiles[index]

            if tile.span == .full {
                views.append(AnyView(
                    tile.view
                        .frame(maxWidth: .infinity)
                ))
                index += 1
            } else {
                if index + 1 < tiles.count && tiles[index + 1].span == .half {
                    views.append(AnyView(
                        HStack(spacing: 16) {
                            tile.view
                                .frame(maxWidth: .infinity)
                            tiles[index + 1].view
                                .frame(maxWidth: .infinity)
                        }
                        .frame(maxWidth: .infinity)
                    ))
                    index += 2
                } else {
                    views.append(AnyView(
                        HStack {
                            tile.view
                                .frame(maxWidth: .infinity)
                        }
                        .frame(maxWidth: .infinity)
                    ))
                    index += 1
                }
            }
        }

        return views
    }
}
