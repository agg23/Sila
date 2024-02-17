//
//  DataProvider.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/17/24.
//

import Foundation
import Combine
import Twitch

enum DataStatus<T, E: Error> {
    case success(_: T)
    case failure(_: E)
    case noData
}

@Observable class DataProvider<T, E: Error> {
    private let taskClosure: (_ api: Helix) -> Task<T, E>
    private var cancellable: AnyCancellable?

    var data: DataStatus<T, E> = .noData

    init(taskClosure: @escaping (_ api: Helix) -> Task<T, E>) {
        self.taskClosure = taskClosure
        self.cancellable = AuthController.shared.subject.sink(receiveCompletion: { _ in

        }, receiveValue: { _ in
            // Received new auth, rerun task
            self.reload()
        })
    }

    func reload() {
        Task {
            let task = taskClosure(AuthController.shared.helixApi)
            do {
                let value = try await task.value
                self.data = .success(value)
            } catch {
                self.data = .failure(error as! E)
            }
        }
    }
}
