//
//  IntentError.swift
//  Sila
//
//  Created by Adam Gastineau on 3/18/24.
//

import Foundation

enum IntentError: Error, CustomLocalizedStringResourceConvertible {
    case unauthorized
    case message(_ message: String)

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .unauthorized:
            return "Please open the Sila for Twitch app before using this shortcut."
        case .message(let message):
            return LocalizedStringResource(stringLiteral: message)
        }
    }
}
