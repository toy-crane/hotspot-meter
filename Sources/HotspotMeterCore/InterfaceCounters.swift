import Darwin

/// Reads 64-bit byte counters for network interfaces.
///
/// `getifaddrs` exposes 32-bit counters that wrap every 4 GB, so this reads
/// `if_data64` through the `NET_RT_IFLIST2` sysctl instead.
public enum InterfaceCounters {
    public static func read(interface name: String) -> ByteCounts? {
        readAll()[name]
    }

    public static func readAll() -> [String: ByteCounts] {
        var mib: [Int32] = [CTL_NET, PF_ROUTE, 0, 0, NET_RT_IFLIST2, 0]
        var length = 0
        guard sysctl(&mib, UInt32(mib.count), nil, &length, nil, 0) == 0, length > 0 else {
            return [:]
        }
        var buffer = [UInt8](repeating: 0, count: length)
        guard sysctl(&mib, UInt32(mib.count), &buffer, &length, nil, 0) == 0 else {
            return [:]
        }

        var result: [String: ByteCounts] = [:]
        buffer.withUnsafeBytes { raw in
            var offset = 0
            while offset + MemoryLayout<if_msghdr>.size <= length {
                let header = raw.loadUnaligned(fromByteOffset: offset, as: if_msghdr.self)
                let messageLength = Int(header.ifm_msglen)
                guard messageLength > 0 else { break }

                if Int32(header.ifm_type) == RTM_IFINFO2,
                   offset + MemoryLayout<if_msghdr2>.size <= length {
                    let message = raw.loadUnaligned(fromByteOffset: offset, as: if_msghdr2.self)
                    if let name = interfaceName(index: message.ifm_index) {
                        result[name] = ByteCounts(
                            received: message.ifm_data.ifi_ibytes,
                            sent: message.ifm_data.ifi_obytes
                        )
                    }
                }
                offset += messageLength
            }
        }
        return result
    }

    private static func interfaceName(index: UInt16) -> String? {
        var name = [CChar](repeating: 0, count: Int(IF_NAMESIZE))
        guard if_indextoname(UInt32(index), &name) != nil else { return nil }
        let bytes = name.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }
        return String(decoding: bytes, as: UTF8.self)
    }
}
