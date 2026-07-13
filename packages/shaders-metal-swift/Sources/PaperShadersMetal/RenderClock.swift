import QuartzCore

/// Mirrors shader-mount.ts:284-298: frame accumulates ms × speed; u_time = frame/1000.
public final class RenderClock {
    public var speed: Double = 1
    public private(set) var frame: Double = 0
    private var last: CFTimeInterval?

    public init() {}

    public var timeSeconds: Float { Float(frame / 1000) }

    public func tick(now: CFTimeInterval) {
        if let last { frame += (now - last) * 1000 * speed }
        last = now
    }

    public func setFrame(_ newFrame: Double) {
        frame = newFrame
        last = nil
    }
}
