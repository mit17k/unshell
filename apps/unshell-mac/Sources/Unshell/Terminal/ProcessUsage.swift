import Darwin

/// CPU and memory of this process (renderers and IO threads included; shells
/// and agents are separate processes and not counted).
final class ProcessUsage {
    struct Sample {
        var cpuPercent: Double
        var residentMB: Double
    }

    private var lastCPU: Double = 0
    private var lastWall: Double = 0

    func sample() -> Sample {
        var usage = rusage()
        getrusage(RUSAGE_SELF, &usage)
        let cpu = seconds(usage.ru_utime) + seconds(usage.ru_stime)

        var time = timespec()
        clock_gettime(CLOCK_MONOTONIC, &time)
        let wall = Double(time.tv_sec) + Double(time.tv_nsec) / 1e9

        var percent = 0.0
        if lastWall > 0, wall > lastWall {
            percent = (cpu - lastCPU) / (wall - lastWall) * 100
        }
        lastCPU = cpu
        lastWall = wall

        return Sample(cpuPercent: percent, residentMB: Double(residentBytes()) / 1_048_576)
    }

    private func seconds(_ value: timeval) -> Double {
        Double(value.tv_sec) + Double(value.tv_usec) / 1e6
    }

    /// phys_footprint matches what Activity Monitor reports as "Memory".
    private func residentBytes() -> UInt64 {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        return result == KERN_SUCCESS ? info.phys_footprint : 0
    }
}
