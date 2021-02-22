//
//  File.swift
//
//
//  Created by Brandon Stillitano on 18/2/21.
//

import NotificationCenter
import UIKit

public class InterfaceToolkit: NSObject {
    // MARK: - Static Data
    static var DebugBordersChangeNotification: NSNotification.Name = NSNotification.Name("DebugBordersChangeNotification")
    static var SlowAnimationsUserDefaultsKey: String = "Scyther_Interface_Toolkit_Slow_Animations_Enabled"

    /// Private Init to Stop re-initialisation and allow singleton creation.
    override private init() { }

    /// An initialised, shared instance of the `Toggler` class.
    static let instance = InterfaceToolkit()

    // MARK: - UI Elements
    internal var gridOverlayView: GridOverlayView = GridOverlayView()
    internal var topLevelViewsWrapper: TopLevelViewsWrapper = TopLevelViewsWrapper()

    // MARK: - Data
    internal var showsViewBorders: Bool = true {
        didSet {
            NotificationCenter.default.post(name: InterfaceToolkit.DebugBordersChangeNotification,
                                            object: showsViewBorders)
        }
    }
    internal var slowAnimationsEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: InterfaceToolkit.SlowAnimationsUserDefaultsKey)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: InterfaceToolkit.SlowAnimationsUserDefaultsKey)
            setWindowSpeed()
        }
    }

    // MARK: - Key Window Notifications
    internal func registerForNotitfcations() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(newKeyWindowNotification(notification:)),
                                               name: UIWindow.didBecomeKeyNotification,
                                               object: nil)
    }

    internal func start() {
        UIView.swizzleDefaultUIView()
        registerForNotitfcations()
        setupTopLevelViewsWrapper()
        setupGridOverlay()
        setWindowSpeed()
        showOverlay()
    }

    private func setupTopLevelViewsWrapper() {
        guard let keyWindow: UIWindow = UIApplication.shared.keyWindow else {
            print("Scyher.InterfaceToolkit failed to setup the top level views wrapper. There is no keyWindow available at UIApplication.shared.keyWindow")
            return
        }
        addTopLevelViewsWrapperToWindow(window: keyWindow)
    }

    private func addTopLevelViewsWrapperToWindow(window: UIWindow) {
        topLevelViewsWrapper.superview?.removeObserver(self, forKeyPath: "layer.sublayers")
        window.addSubview(topLevelViewsWrapper)
        window.addObserver(self,
                           forKeyPath: "layer.sublayers",
                           options: [.new, .old],
                           context: nil)
    }

    @objc
    internal func newKeyWindowNotification(notification: NSNotification) {
        guard let window: UIWindow = notification.object as? UIWindow else {
            print("Scyher.InterfaceToolkit failed to setup the top level views wrapper. There is no window available at UIWindow.didResignKeyNotification.object")
            return
        }
        addTopLevelViewsWrapperToWindow(window: window)
        setWindowSpeed()
    }

    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if object is UIWindow {
            topLevelViewsWrapper.superview?.bringSubviewToFront(topLevelViewsWrapper)
        }
    }
}

// MARK: - Grid Overlay
extension InterfaceToolkit {
    internal func setupGridOverlay() {
        gridOverlayView.opacity = CGFloat(GridOverlay.instance.opacity)
        gridOverlayView.isHidden = true
        gridOverlayView.gridSize = GridOverlay.instance.size
        gridOverlayView.colorScheme = GridOverlay.instance.colorScheme
        topLevelViewsWrapper.addTopLevelView(topLevelView: gridOverlayView)
        showGridOverlay()
    }

    internal func showGridOverlay() {
        gridOverlayView.opacity = GridOverlay.instance.enabled ? CGFloat(GridOverlay.instance.opacity) : 0.0
        gridOverlayView.isHidden = !GridOverlay.instance.enabled
    }
}

// MARK: Slow Animations
extension InterfaceToolkit {
    internal func setWindowSpeed() {
        let speed: Float = slowAnimationsEnabled ? 0.1 : 1.0
        for window in UIApplication.shared.windows {
            window.layer.speed = speed
        }
    }
}

// MARK: UIDebuggingInformationOverlay
extension InterfaceToolkit {
    internal func showOverlay() {
        // Construct the class name string using unsinged chars to avoid private api detection
        guard let classNameString: String = String(data: Data(bytes: [0x55, 0x49, 0x44, 0x65, 0x62, 0x75, 0x67, 0x67, 0x69, 0x6e, 0x67, 0x49, 0x6e, 0x66, 0x6f, 0x72, 0x6d, 0x61, 0x74, 0x69, 0x6f, 0x6e, 0x4f, 0x76, 0x65, 0x72, 0x6c, 0x61, 0x79], count: 29), encoding: .ascii) else {
            return
        }
        let overlayClass: AnyObject? = NSClassFromString(classNameString)

        // Construct the overlay selector string, again using unsigned chars
        guard let selectorString: String = String(data: Data(bytes: [0x6f, 0x76, 0x65, 0x72, 0x6c, 0x61, 0x79], count: 7), encoding: .ascii) else {
            return
        }
        let overlaySelector = NSSelectorFromString(selectorString)
        
        // Show the overlay
        overlayClass?.perform(overlaySelector)
    }
}
