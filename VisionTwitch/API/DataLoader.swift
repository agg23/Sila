//
//  DataLoader.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/21/24.
//

import SwiftUI

enum Status<T> {
    case loading(T?)
    case idle
    case finished(T)
    case error(Error)
}

@Observable class DataLoader<T, Changable: Equatable> {
    var status: Status<T> = .idle
    var changable: Changable? = nil
    var task: (() async throws -> T)? = nil

    func get(task: @escaping () async throws -> T, onChange: Changable? = nil) -> Status<T> {
        self.task = task

        switch self.status {
        case .idle:
            // Save changable for future updates
            self.changable = onChange
        default:
            break
        }

        if onChange != nil && onChange != self.changable {
            // We need to refresh
            Task {
                await self.refresh()
            }
            self.changable = onChange
        }

        return self.status
    }

    func onAppear() async {
        switch self.status {
        case .idle:
            // We want to refresh only if we haven't fetched data before
            await self.refresh()
        default:
            break
        }
    }

    func refresh() async {
        self.status = await self.refreshDeferredData()
    }

    func refresh(minDurationSecs: UInt64) async {
        async let newStatusAsync = await self.refreshDeferredData(preventLoadingState: true)
        async let sleep: ()? = try? await Task.sleep(nanoseconds: minDurationSecs * NSEC_PER_SEC)
        let (newStatus, _) = await (newStatusAsync, sleep)

        self.status = newStatus
    }

    private func refreshDeferredData(preventLoadingState: Bool = false) async -> Status<T> {
        guard let task = self.task else {
            fatalError("Incorrectly set up DataLoader")
        }

        do {
            var existingData: T? = nil

            switch self.status {
            case .loading(let existing):
                existingData = existing
            case .finished(let existing):
                existingData = existing
            default:
                break
            }

            if !preventLoadingState {
                self.status = .loading(existingData)
            }

            return try await .finished(task())
        } catch {
            return .error(error)
        }
    }
}
