import Foundation
#if os(Linux)
import Glibc
#elseif os(Windows)
import WinSDK
#endif

public enum LocalIPAddressProvider {
    public static func localIPv4Address() -> String? {
        #if os(Windows)
        return nil
        #else
        var address: String?
        var interfaces: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&interfaces) == 0, let firstInterface = interfaces else {
            return nil
        }
        defer { freeifaddrs(interfaces) }

        for pointer in sequence(first: firstInterface, next: { $0.pointee.ifa_next }) {
            let interface = pointer.pointee
            let flags = Int32(interface.ifa_flags)
            let isUp = (flags & IFF_UP) == IFF_UP
            let isLoopback = (flags & IFF_LOOPBACK) == IFF_LOOPBACK
            guard isUp, !isLoopback, interface.ifa_addr.pointee.sa_family == UInt8(AF_INET) else {
                continue
            }

            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            let result = getnameinfo(
                interface.ifa_addr,
                socketAddressLength(for: interface.ifa_addr.pointee),
                &hostname,
                socklen_t(hostname.count),
                nil,
                0,
                NI_NUMERICHOST
            )

            if result == 0 {
                let bytes = hostname.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }
                address = String(decoding: bytes, as: UTF8.self)
                break
            }
        }

        return address
        #endif
    }

    #if !os(Windows)
    private static func socketAddressLength(for address: sockaddr) -> socklen_t {
        #if os(Linux)
        if address.sa_family == sa_family_t(AF_INET) {
            return socklen_t(MemoryLayout<sockaddr_in>.size)
        }
        return socklen_t(MemoryLayout<sockaddr>.size)
        #else
        return socklen_t(address.sa_len)
        #endif
    }
    #endif
}
