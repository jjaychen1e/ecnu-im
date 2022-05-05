//
//  Pool.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/4.
//

import Foundation
import LinkPresentation

protocol PoolTask: Comparable {
    associatedtype Result

    /// Could be changed on the fly(a same request fired)
    var creationDate: Date { get set }

    var description: String? { get }

    func start(completionHandler: @escaping (Result?) -> Void)
    func cancel()
}

final class LPMetadataLoader {
    static let shared = LPMetadataLoader()

    private init() {}

    private class LPMetadataLoadTask: PoolTask {
        init(creationDate: Date, url: URL) {
            self.creationDate = creationDate
            self.url = url
        }

        var description: String? {
            "LPMetadataLoadTask(\(creationDate.timeIntervalSince1970)): \(url.absoluteString)"
        }

        var creationDate: Date
        var url: URL
        var provider: LPMetadataProvider?

        func start(completionHandler: @escaping (LPLinkMetadata?) -> Void) {
            DispatchQueue.main.async { [weak self] in
                if let self = self {
                    self.provider = LPMetadataProvider()
                    self.provider!.startFetchingMetadata(for: self.url) { [weak self] metadata, error in
                        if let metadata = metadata {
                            completionHandler(metadata)
                        } else {
                            completionHandler(nil)
                        }
                        if let self = self {
                            self.provider = nil
                        }
                    }
                }
            }
        }

        func cancel() {
            // TODO: is this necessary?
            DispatchQueue.main.async { [weak self] in
                if let self = self {
                    self.provider?.cancel()
                    self.provider = nil
                }
            }
        }

        static func == (lhs: LPMetadataLoadTask, rhs: LPMetadataLoadTask) -> Bool {
            lhs.url == rhs.url
        }

        static func < (lhs: LPMetadataLoadTask, rhs: LPMetadataLoadTask) -> Bool {
            lhs.creationDate < rhs.creationDate
        }
    }

    private let pool = TaskPool<LPMetadataLoadTask>()

    private func persist(metadata: LPLinkMetadata) {
        LPLinkMetadataStorage.shared.store(metadata)
    }

    private func readFromStorage(url: URL) -> LPLinkMetadata? {
        LPLinkMetadataStorage.shared.metadata(for: url)
    }

    private func postProcess(metadata: LPLinkMetadata) {
        persist(metadata: metadata)
    }

    func request(url: URL, completionHandler: @escaping (LPLinkMetadata?) -> Void) {
        let task = LPMetadataLoadTask(creationDate: .now, url: url)
        Task {
            await pool.add(task: task, completionHandler: { metadata in
                if let metadata = metadata {
                    completionHandler(metadata)
                    self.postProcess(metadata: metadata)
                } else {
                    completionHandler(nil)
                }
            })
        }
    }
}

actor TaskPool<T: PoolTask> {
    private class InternalPoolTask<T: PoolTask>: Comparable {
        static func == (lhs: InternalPoolTask<T>, rhs: InternalPoolTask<T>) -> Bool {
            lhs.task == rhs.task
        }

        static func < (lhs: InternalPoolTask<T>, rhs: InternalPoolTask<T>) -> Bool {
            lhs.task < rhs.task
        }

        init(task: T, completionHandler: @escaping (T.Result?) -> Void) {
            self.task = task
            self.completionHandler = [completionHandler]
        }

        var task: T
        var completionHandler: [(T.Result?) -> Void]
    }

    private let maxFetchCount = 6
    private var fetchingPriorityQueue: SortedSet<InternalPoolTask<T>> = .init()
    private var pendingPriorityQueue: SortedSet<InternalPoolTask<T>> = .init()

    func add<Result>(task: T, completionHandler: @escaping (Result?) -> Void) where T.Result == Result {
        defer {
            print("Pool - Statistics(add): fetching task count: \(fetchingPriorityQueue.count), pending task count: \(pendingPriorityQueue.count). \(Unmanaged.passUnretained(self).toOpaque())")
        }

        var internalTaskIndex: Int?
        for index in 0 ..< fetchingPriorityQueue.count {
            if fetchingPriorityQueue[index].task == task {
                internalTaskIndex = index
                break
            }
        }

        if let internalTaskIndex = internalTaskIndex {
            // We need to extract and insert to make sure the order is correct
            let internalTask = fetchingPriorityQueue[internalTaskIndex]
            fetchingPriorityQueue.remove(internalTask)
            internalTask.task.creationDate = .now
            fetchingPriorityQueue.insert(internalTask)
            print("Pool - Start(already running, so we changed the completionHandler): \(internalTask.task.description ?? "No description")")
            internalTask.completionHandler.append(completionHandler)

            return
        }

        pendingPriorityQueue.filter { $0.task == task }.forEach {
            pendingPriorityQueue.remove($0)
            print("Pool - Add while remove a same pending task: \($0.task.description ?? "No description")")
        }

        while fetchingPriorityQueue.count >= maxFetchCount, task.creationDate > fetchingPriorityQueue.last!.task.creationDate {
            if let internalTask = fetchingPriorityQueue.popFirst() {
                internalTask.task.cancel()
                pendingPriorityQueue.insert(internalTask)
                print("Pool - Pending(because higher priority task starts): \(internalTask.task.description ?? "No description")")
            }
        }

        let internalTask = InternalPoolTask(task: task, completionHandler: completionHandler)
        if fetchingPriorityQueue.count >= maxFetchCount {
            pendingPriorityQueue.insert(internalTask)
            print("Pool - Start failed(no available space): \(task.description ?? "No description")")
            return
        }

        print("Pool - Start: \(task.description ?? "No description")")
        fetchingPriorityQueue.insert(internalTask)
        task.start { metadata in
            Task {
                self.didFinished(internalTask: internalTask, result: metadata)
            }
        }
    }

    func cancel(task: T) {
        fetchingPriorityQueue
            .filter { $0.task == task }
            .forEach {
                $0.task.cancel()
                fetchingPriorityQueue.remove($0)
            }

        pendingPriorityQueue
            .filter { $0.task == task }
            .forEach {
                $0.task.cancel()
                pendingPriorityQueue.remove($0)
            }
    }

    private func didFinished(internalTask: InternalPoolTask<T>, result: T.Result?) {
        defer {
            print("Pool - Statistics(didFinished): fetching task count: \(fetchingPriorityQueue.count), pending task count: \(pendingPriorityQueue.count)")
        }
        print("Pool - Finished: \(internalTask.task.description ?? "No description")")
        for completion in internalTask.completionHandler {
            completion(result)
        }
        fetchingPriorityQueue.filter { $0.task == internalTask.task }.forEach { fetchingPriorityQueue.remove($0) }
        pendingPriorityQueue.filter { $0.task == internalTask.task }.forEach { pendingPriorityQueue.remove($0) }
        tryToStartPendingTask()
    }

    private func tryToStartPendingTask() {
        if fetchingPriorityQueue.count < maxFetchCount {
            if let internalTask = pendingPriorityQueue.popLast() {
                fetchingPriorityQueue.insert(internalTask)
                print("Pool - Restart: \(internalTask.task.description ?? "No description")")
                internalTask.task.start { result in
                    Task {
                        self.didFinished(internalTask: internalTask, result: result)
                    }
                }
            }
        }
    }
}
