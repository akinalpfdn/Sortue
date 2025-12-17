import SwiftUI

extension Font {
    static let appFontName = "VarelaRound-Regular"

    static func app(_ style: Font.TextStyle) -> Font {
        switch style {
        case .largeTitle: return .custom(appFontName, size: 36, relativeTo: .largeTitle)
        case .title: return .custom(appFontName, size: 30, relativeTo: .title)
        case .title2: return .custom(appFontName, size: 24, relativeTo: .title2)
        case .title3: return .custom(appFontName, size: 22, relativeTo: .title3)
        case .headline: return .custom(appFontName, size: 18, relativeTo: .headline)
        case .body: return .custom(appFontName, size: 18, relativeTo: .body)
        case .callout: return .custom(appFontName, size: 18, relativeTo: .callout)
        case .subheadline: return .custom(appFontName, size: 17, relativeTo: .subheadline)
        case .footnote: return .custom(appFontName, size: 15, relativeTo: .footnote)
        case .caption: return .custom(appFontName, size: 14, relativeTo: .caption)
        case .caption2: return .custom(appFontName, size: 13, relativeTo: .caption2)
        @unknown default: return .custom(appFontName, size: 19, relativeTo: .body)
        }
    }
    
    // Helper for specific sizes, maintaining scaling
    static func app(size: CGFloat) -> Font {
        return .custom(appFontName, size: size)
    }
}
