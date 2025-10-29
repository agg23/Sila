//
//  Date.swift
//  Sila
//
//  Created by Adam Gastineau on 10/26/25.
//

import Foundation

class RuntimeFormatter: DateComponentsFormatter, @unchecked Sendable {
    static let shared = RuntimeFormatter()

    override init() {
        super.init()

        self.allowedUnits = [.hour, .minute, .second]
        self.unitsStyle = .positional
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class TimeFormatter: DateFormatter, @unchecked Sendable {
    static let shared = TimeFormatter()

    override init() {
        super.init()
        
        self.timeStyle = .medium
        self.dateStyle = .none
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
