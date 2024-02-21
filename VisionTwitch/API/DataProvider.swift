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

    var lastFetchToken: String?

    init(taskClosure: @escaping (_ api: Helix) -> Task<T, E>, requiresAuth: Bool) {
        self.taskClosure = taskClosure
        self.requiresAuth = requiresAuth
    }

    func reload() async {
        let _ = await self.reloadTask().result
    }

    func reloadTask() -> Task<Void, Error> {
        return Task {
            let task = taskClosure(AuthController.shared.helixApi)
            self.lastFetchToken = AuthController.shared.currentToken
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
                            self.reauth()
                        }
                    case .requestFailed(_, let status, _):
                        if status == 401 {
                            // Need to relogin
                            self.reauth()
                        }
                    default:
                        break
                    }
                }
            }
        }
    }

    func register() {
        self.cancellable = AuthController.shared.authChangeSubject.sink(receiveCompletion: { _ in }, receiveValue: { _ in
            // Received new auth, rerun task
            if !self.requiresAuth || AuthController.shared.isAuthorized {
                self.reloadTask()
            }
        })
    }

    func cancel() {
        self.cancellable?.cancel()
        self.cancellable = nil
    }

    private func reauth() {
        // Mark request as loading so it's clear to the user what's happening
        self.data = .loading(self.currentData())

        if AuthController.shared.isAuthorized {
            // Attempt logging in again
            AuthController.shared.requestReauth()
        } else {
            // Get new public access token
            Task {
                do {
                    try await AuthController.shared.updatePublicToken()
                } catch {
                    print("Failed to update public access token: \(error.localizedDescription)")
                    self.data = .failure(HelixError.invalidResponse(rawResponse: error.localizedDescription) as! E)
                }
            }
        }
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
