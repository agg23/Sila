//
//  UIImageColors+Default.swift
//  WidgetsExtension
//
//  Created by Adam Gastineau on 12/7/25.
//

import UIKit
import UIImageColors

extension UIImageColors {
    static let defaultColors = UIImageColors(background: UIColor(red: 0x81 / 255, green: 0x22 / 255, blue: 0x59 / 255, alpha: 1.0), primary: .white.withAlphaComponent(0.9), secondary: .tertiaryLabel, detail: .secondaryLabel)
}
