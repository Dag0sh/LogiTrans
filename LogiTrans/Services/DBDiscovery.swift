import Foundation
import Network
import Darwin

enum DBDiscovery {

    // MARK: - Public API

    /// Scans all local subnets (plus known hotspot ranges) for a host with open port 5432.
    static func findDBHost(port: Int = 5432, timeout: TimeInterval = 1.2) async -> String? {
        let prefixes = subnetsToScan()
        guard !prefixes.isEmpty else {
            print("[Discovery] Нет сетевых интерфейсов")
            return nil
        }
        print("[Discovery] Сканирую подсети: \(prefixes.joined(separator: ", ")) порт \(port)")

        return await withTaskGroup(of: String?.self) { group in
            for prefix in prefixes {
                for i in 1...254 {
                    let host = "\(prefix)\(i)"
                    group.addTask {
                        let open = await isPortOpen(host: host, port: port, timeout: timeout)
                        if open { print("[Discovery] Найден открытый порт \(port): \(host)") }
                        return open ? host : nil
                    }
                }
            }
            var found: String?
            for await result in group {
                if let host = result { found = host; break }
            }
            group.cancelAll()
            return found
        }
    }

    // MARK: - Interface discovery

    // Virtual tunnel interfaces that give false positives on any port check:
    // ipsec* — IKEv2/IPsec tunnels (192.0.0.x DS-Lite)
    // utun*  — VPN / Apple Private Relay (198.18.x.x benchmarking range)
    // awdl*, llw* — peer-to-peer / low-latency WiFi
    private static let skipInterfacePrefixes = ["lo", "ipsec", "utun", "awdl", "llw"]

    // IP prefixes that belong to virtual/special-use ranges and produce false positives
    private static let skipIPPrefixes = ["192.0.0.", "198.18.", "198.19.", "169.254.", "100.64."]

    /// Returns unique /24 subnet prefixes from real physical interfaces only.
    private static func subnetsToScan() -> [String] {
        var prefixes: [String] = []

        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return ["172.20.10."] }
        defer { freeifaddrs(ifaddr) }

        var ptr = ifaddr
        while let current = ptr {
            defer { ptr = current.pointee.ifa_next }
            let iface = current.pointee
            guard iface.ifa_addr != nil,
                  iface.ifa_addr.pointee.sa_family == UInt8(AF_INET) else { continue }

            let name = String(cString: iface.ifa_name)
            guard !skipInterfacePrefixes.contains(where: { name.hasPrefix($0) }) else { continue }

            var buf = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            guard getnameinfo(iface.ifa_addr,
                              socklen_t(iface.ifa_addr.pointee.sa_len),
                              &buf, socklen_t(buf.count),
                              nil, 0, NI_NUMERICHOST) == 0 else { continue }

            let ip = String(cString: buf)
            guard !ip.isEmpty,
                  let prefix = subnetPrefix(from: ip),
                  !skipIPPrefixes.contains(where: { prefix.hasPrefix($0) }) else { continue }

            print("[Discovery] Интерфейс \(name): \(ip) → подсеть \(prefix)")
            if !prefixes.contains(prefix) { prefixes.append(prefix) }
        }

        // Always include iPhone hotspot range (bridge100 = 172.20.10.1, clients get .2+)
        if !prefixes.contains("172.20.10.") { prefixes.append("172.20.10.") }

        return prefixes
    }

    private static func subnetPrefix(from ip: String) -> String? {
        let parts = ip.split(separator: ".")
        guard parts.count == 4 else { return nil }
        return "\(parts[0]).\(parts[1]).\(parts[2])."
    }

    // MARK: - Port check

    private static func isPortOpen(host: String, port: Int, timeout: TimeInterval) async -> Bool {
        await withCheckedContinuation { continuation in
            let conn = NWConnection(
                host: NWEndpoint.Host(host),
                port: NWEndpoint.Port(integerLiteral: UInt16(port)),
                using: .tcp
            )
            let lock = NSLock()
            var done = false

            func finish(_ result: Bool) {
                lock.lock(); defer { lock.unlock() }
                guard !done else { return }
                done = true
                conn.cancel()
                continuation.resume(returning: result)
            }

            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) { finish(false) }
            conn.stateUpdateHandler = { state in
                switch state {
                case .ready:               finish(true)
                case .failed, .cancelled:  finish(false)
                default: break
                }
            }
            conn.start(queue: .global())
        }
    }
}
