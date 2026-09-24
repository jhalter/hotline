import SwiftUI
import AppKit
import QuartzCore

struct TrackerBookmarkServerView: View {
  let server: BookmarkServer

  var body: some View {
    HStack(alignment: .center, spacing: 6) {
      Image("Server")
        .resizable()
        .scaledToFit()
        .frame(width: 16, height: 16, alignment: .center)
      Text(self.server.name ?? "Server").lineLimit(1).truncationMode(.tail)
      if let serverDescription = self.server.description {
        Text(serverDescription)
          .foregroundStyle(.secondary)
          .lineLimit(1)
          .truncationMode(.tail)
      }
      Spacer(minLength: 0)
      if self.server.users > 0 {
        Text(String(self.server.users))
          .foregroundStyle(.secondary)
          .lineLimit(1)

        TrackerStatusLight()
          .frame(width: 7, height: 7)
          .padding(.trailing, 6)
          .accessibilityHidden(true)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

/// Lets Core Animation pulse the dot without updating SwiftUI on every frame.
private struct TrackerStatusLight: NSViewRepresentable {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  func makeNSView(context: Context) -> StatusLightView {
    StatusLightView(frame: .zero)
  }

  func updateNSView(_ nsView: StatusLightView, context: Context) {
    nsView.reduceMotion = self.reduceMotion
  }

  static func dismantleNSView(_ nsView: StatusLightView, coordinator: ()) {
    nsView.tearDown()
  }

  final class StatusLightView: NSView {
    private let dotLayer = CALayer()
    private static let animationKey = "statusPulse"
    private var isActive = true

    var reduceMotion = true {
      didSet {
        self.updateAnimation()
      }
    }

    override init(frame frameRect: NSRect) {
      super.init(frame: frameRect)
      self.wantsLayer = true
      self.layer?.addSublayer(self.dotLayer)
      self.updateColor()
    }

    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
      super.layout()
      CATransaction.begin()
      CATransaction.setDisableActions(true)
      self.dotLayer.frame = self.bounds
      self.dotLayer.cornerRadius = min(self.bounds.width, self.bounds.height) / 2
      self.dotLayer.contentsScale = self.window?.backingScaleFactor ?? 1
      CATransaction.commit()
    }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
      NotificationCenter.default.removeObserver(self, name: NSWindow.didChangeOcclusionStateNotification, object: self.window)
      self.stopAnimating()
      super.viewWillMove(toWindow: newWindow)
    }

    override func viewDidMoveToWindow() {
      super.viewDidMoveToWindow()
      if self.isActive, let window = self.window {
        NotificationCenter.default.addObserver(
          self,
          selector: #selector(self.windowVisibilityChanged(_:)),
          name: NSWindow.didChangeOcclusionStateNotification,
          object: window
        )
      }
      self.needsLayout = true
      self.updateAnimation()
    }

    override func viewDidHide() {
      super.viewDidHide()
      self.stopAnimating()
    }

    override func viewDidUnhide() {
      super.viewDidUnhide()
      self.updateAnimation()
    }

    override func viewDidChangeEffectiveAppearance() {
      super.viewDidChangeEffectiveAppearance()
      self.updateColor()
    }

    override func viewDidChangeBackingProperties() {
      super.viewDidChangeBackingProperties()
      self.needsLayout = true
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
      nil
    }

    private func updateColor() {
      CATransaction.begin()
      CATransaction.setDisableActions(true)
      self.effectiveAppearance.performAsCurrentDrawingAppearance {
        self.dotLayer.backgroundColor = NSColor.fileComplete.cgColor
      }
      CATransaction.commit()
    }

    @objc private func windowVisibilityChanged(_ notification: Notification) {
      self.updateAnimation()
    }

    private func updateAnimation() {
      guard self.isActive,
            !self.reduceMotion,
            !self.isHiddenOrHasHiddenAncestor,
            self.window?.occlusionState.contains(.visible) == true else {
        self.stopAnimating()
        return
      }

      // SwiftUI updates must not restart an already-running pulse.
      guard self.dotLayer.animation(forKey: Self.animationKey) == nil else { return }

      let pulse = CAKeyframeAnimation(keyPath: "opacity")
      pulse.values = [1.0, 1.0, 0.6, 1.0]
      pulse.keyTimes = [0.0, 2.0 / 3.0, 2.5 / 3.0, 1.0] as [NSNumber]
      pulse.duration = 3.0
      pulse.timingFunctions = [
        CAMediaTimingFunction(name: .linear),
        CAMediaTimingFunction(name: .easeInEaseOut),
        CAMediaTimingFunction(name: .easeInEaseOut),
      ]
      pulse.repeatCount = .infinity
      self.dotLayer.add(pulse, forKey: Self.animationKey)
    }

    private func stopAnimating() {
      self.dotLayer.removeAnimation(forKey: Self.animationKey)
    }

    func tearDown() {
      self.isActive = false
      NotificationCenter.default.removeObserver(self)
      self.stopAnimating()
    }
  }
}
