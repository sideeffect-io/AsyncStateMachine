
#if DEBUG
#if canImport(ObjectiveC)
import Foundation

/// This function generates a failure immediately and unconditionally.
///
/// Dynamically creates and records an `XCTIssue` under the hood that captures the source code
/// context of the caller. Useful for defining assertion helpers that fail in indirect code
/// paths, where the `file` and `line` of the failure have not been realized.
///
/// - Parameter message: An optional description of the assertion, for inclusion in test
///   results.
public func XCTFail(_ message: String = "") {
    guard
        let XCTestObservationCenter = NSClassFromString("XCTestObservationCenter")
            as Any as? NSObjectProtocol,
        String(describing: XCTestObservationCenter) != "<null>",
        let shared = XCTestObservationCenter.perform(Selector(("sharedTestObservationCenter")))?
            .takeUnretainedValue(),
        let observers = shared.perform(Selector(("observers")))?
            .takeUnretainedValue() as? [AnyObject],
        let observer =
            observers
            .first(where: { NSStringFromClass(type(of: $0)) == "XCTestMisuseObserver" }),
        let currentTestCase = observer.perform(Selector(("currentTestCase")))?
            .takeUnretainedValue(),
        let XCTIssue = NSClassFromString("XCTIssue")
            as Any as? NSObjectProtocol,
        let alloc = XCTIssue.perform(NSSelectorFromString("alloc"))?
            .takeUnretainedValue(),
        let issue =
            alloc
            .perform(
                Selector(("initWithType:compactDescription:")),
                with: 0,
                with: message.isEmpty ? "failed" : message
            )?
            .takeUnretainedValue()
    else {
        #if canImport(Darwin)
        let indentedMessage = message.split(separator: "\n", omittingEmptySubsequences: false)
            .map { "  \($0)" }
            .joined(separator: "\n")
        
        breakpoint(
            """
            ---
            Warning: "XCTestDynamicOverlay.XCTFail" has been invoked outside of tests\
            \(message.isEmpty ? "." : "with the message:\n\n\(indentedMessage)")
            
            This function should only be invoked during an XCTest run, and is a no-op when run in \
            application code. If you or a library you depend on is using "XCTFail" for \
            test-specific code paths, ensure that these same paths are not called in your \
            application.
            ---
            """
        )
        #endif
        return
    }
    
    _ = currentTestCase.perform(Selector(("recordIssue:")), with: issue)
}

/// This function generates a failure immediately and unconditionally.
///
/// Dynamically calls `XCTFail` with the given file and line. Useful for defining assertion
/// helpers that have the source code context at hand and want to highlight the direct caller
/// of the helper.
///
/// - Parameter message: An optional description of the assertion, for inclusion in test
///   results.
public func XCTFail(_ message: String = "", file: StaticString, line: UInt) {
    _XCTFailureHandler(nil, true, "\(file)", line, "\(message.isEmpty ? "failed" : message)", nil)
}

private typealias XCTFailureHandler = @convention(c) (
    AnyObject?, Bool, UnsafePointer<CChar>, UInt, String, String?
) -> Void
private let _XCTFailureHandler = unsafeBitCast(
    dlsym(dlopen(nil, RTLD_LAZY), "_XCTFailureHandler"),
    to: XCTFailureHandler.self
)
#else
// NB: It seems to be safe to import XCTest on Linux
@_exported import func XCTest.XCTFail
#endif
#else
/// This function generates a failure immediately and unconditionally.
///
/// Dynamically creates and records an `XCTIssue` under the hood that captures the source code
/// context of the caller. Useful for defining assertion helpers that fail in indirect code
/// paths, where the `file` and `line` of the failure have not been realized.
///
/// - Parameter message: An optional description of the assertion, for inclusion in test
///   results.
public func XCTFail(_ message: String = "") {}

/// This function generates a failure immediately and unconditionally.
///
/// Dynamically creates and records an `XCTIssue` under the hood that captures the source code
/// context of the caller. Useful for defining assertion helpers that fail in indirect code
/// paths, where the `file` and `line` of the failure have not been realized.
///
/// - Parameter message: An optional description of the assertion, for inclusion in test
///   results.
public func XCTFail(_ message: String = "", file: StaticString, line: UInt) {}
#endif

#if canImport(Darwin)
import Darwin

/// Raises a debug breakpoint if a debugger is attached.
@inline(__always)
@usableFromInline
func breakpoint(_ message: @autoclosure () -> String = "") {
    #if DEBUG
    // https://github.com/bitstadium/HockeySDK-iOS/blob/c6e8d1e940299bec0c0585b1f7b86baf3b17fc82/Classes/BITHockeyHelper.m#L346-L370
    var name: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
    var info: kinfo_proc = kinfo_proc()
    var info_size = MemoryLayout<kinfo_proc>.size
    
    let isDebuggerAttached = name.withUnsafeMutableBytes {
        $0.bindMemory(to: Int32.self).baseAddress
            .map {
                sysctl($0, 4, &info, &info_size, nil, 0) != -1 && info.kp_proc.p_flag & P_TRACED != 0
            }
            ?? false
    }
    
    if isDebuggerAttached {
        fputs(
            """
          \(message())
          
          Caught debug breakpoint. Type "continue" ("c") to resume execution.
          
          """,
            stderr
        )
        raise(SIGTRAP)
    }
    #endif
}
#endif
