//
//  CachedColors.swift
//  Sila
//
//  Created by Adam Gastineau on 3/16/24.
//

import UIKit

class CachedColors {
    private var colors: [String: UIColor] = [:]

    func get(hexColor string: String) -> UIColor {
        if let color = self.colors[string] {
            return color
        }

        let newColor = UIColor.hexStringToUIColor(hex: string)
        self.colors[string] = newColor

        return newColor
    }
}
