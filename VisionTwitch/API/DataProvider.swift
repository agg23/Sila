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
    case loading(_: T?)
    case noData
}

@Observable class DataProvider<T, E: Error> {
    private let taskClosure: (_ api: Helix) -> Task<T, E>
    private var cancellable: AnyCancellable?
    private let requiresAuth: Bool

    var data: DataStatus<T, E> = .noData

    init(taskClosure: @escaping (_ api: Helix) -> Task<T, E>, requiresAuth: Bool) {
        self.taskClosure = taskClosure
        self.requiresAuth = requiresAuth
        self.cancellable = AuthController.shared.authChangeSubject.sink(receiveCompletion: { _ in }, receiveValue: { _ in
            // Received new auth, rerun task
            if !self.requiresAuth || AuthController.shared.isAuthorized {
                self.reload()
            }
        })
    }

    func reload() {
        Task {
            let task = taskClosure(AuthController.shared.helixApi)
            do {
                self.data = .loading(self.currentData())
                let value = try await task.value
                self.data = .success(value)
            } catch {
                print("Request error: \(error)")
                self.data = .failure(error as! E)

                if let helixError = error as? HelixError {
                    switch helixError {
                    case .invalidErrorResponse(let status, _):
                        if status == 401 {
                            // Need to relogin
                            AuthController.shared.requestReauth()
                        }
                    case .requestFailed(_, let status, _):
                        if status == 401 {
                            // Need to relogin
                            AuthController.shared.requestReauth()
                        }
                    default:
                        break
                    }
                }
            }
        }
    }

    func cancel() {
        self.cancellable?.cancel()
        self.cancellable = nil
    }

    private func currentData() -> T? {
        switch self.data {
        case .success(let data):
            return data
        case .loading(let data):
            return data
        case .noData, .failure:
            return nil
        }
    }
}
