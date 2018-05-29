import UIKit

@objc public extension UIViewController {
  private func viewControllerWasInjected(_ notification: Notification) -> Bool {
    if Injection.objectWasInjected(self, notification: notification) {
      return true
    }
    guard let object = Injection.object(from: notification) else {
      return false
    }

    var shouldRespondToInjection: Bool = false

    /// Check if parent view controller should be injected.
    if !childViewControllers.isEmpty {
      for childViewController in childViewControllers {
        if object.classForCoder == childViewController.classForCoder {
          shouldRespondToInjection = true
          break
        }
      }
    }

    /// Check if object matches self.
    if !shouldRespondToInjection {
      shouldRespondToInjection = object.classForCoder == self.classForCoder
    }

    return shouldRespondToInjection
  }

  private func removeChildViewControllers() {
    childViewControllers.forEach {
      $0.view.removeFromSuperview()
      $0.removeFromParentViewController()
    }
  }

  private func viewDidLoadIfNeeded(_ notification: Notification) {
    guard Injection.isLoaded else { return }
    guard viewControllerWasInjected(notification) else { return }

    NotificationCenter.default.removeObserver(self)
    removeChildViewControllers()
    removeViewsAndLayers()
    viewDidLoad()
    view.subviews.forEach {
      $0.setNeedsLayout()
      $0.layoutIfNeeded()
      $0.setNeedsDisplay()
    }

    view.subviews.filter({ $0.frame.size == .zero }).forEach {
      $0.sizeToFit()
    }
  }

  private func removeViewsAndLayers() {
    view.subviews.forEach {
      $0.removeFromSuperview()
    }

    if let sublayers = self.view.layer.sublayers {
      sublayers.forEach { $0.removeFromSuperlayer() }
    }
  }

  @objc func injected(_ notification: Notification) {
    viewDidLoadIfNeeded(notification)
  }
}
