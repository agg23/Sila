//
//  Error.swift
//  WidgetsExtension
//
//  Created by Adam Gastineau on 12/9/25.
//

import Foundation

enum WidgetError: Error, CustomLocalizedStringResourceConvertible {
    case networkError

    var localizedStringResource: LocalizedStringResource {
        let literal = switch self {
        case .networkError:
            "A network error occurred"
        }

        return LocalizedStringResource(stringLiteral: literal)
    }
}
