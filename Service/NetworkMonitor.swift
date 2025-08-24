//
//  NetworkMonitor.swift
//  FrenchLearning
//
//  Created by 藤原匡都 on 2025/08/24.
//

import Foundation
import Network
import Combine

final class NetworkMonitor: ObservableObject {
    @Published private(set) var isConnected: Bool = true
    @Published private(set) var isExpensive: Bool = false   // 従量課金回線（例：テザリング）
    @Published private(set) var interface: NWInterface.InterfaceType? = nil

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = (path.status == .satisfied)
                self?.isExpensive = path.isExpensive
                if path.usesInterfaceType(.wifi) { self?.interface = .wifi }
                else if path.usesInterfaceType(.cellular) { self?.interface = .cellular }
                else if path.usesInterfaceType(.wiredEthernet) { self?.interface = .wiredEthernet }
                else { self?.interface = nil }
            }
        }
        monitor.start(queue: queue)
    }

    deinit { monitor.cancel() }
}

