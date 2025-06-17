//
//  ThreeDimensionModelViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 04/02/2025.
//

import UIKit
import SceneKit
import GLTFKit2
import KukaiCoreSwift

protocol ThreeDimensionModelViewControllerDelegate: AnyObject {
	func threeDimensionModelLoadingError(_ error: Error?)
}

class ThreeDimensionModelViewController: UIViewController {
	
	public weak var delegate: ThreeDimensionModelViewControllerDelegate? = nil
	
	private let sceneView = SCNView()
	private let camera = SCNCamera()
	private let cameraNode = SCNNode()
	private var animations = [GLTFSCNAnimation]()
	private let activityIndicator = UIActivityIndicatorView()
	
	private let fullScreenButton = UIButton()
	private var isFullscreen = false
	private var controlButtonsAnimating = false
	private var controlButtonsDisplayed = false
	private var controlButtonDisplayTimer: Timer? = nil
	private var previousSuperView: UIView? = nil
	private var fullscreenButtonYConstraint = NSLayoutConstraint()
	private var globalPoint: CGPoint = CGPoint(x: 0, y: 0)
	
	private var asset: GLTFAsset? = nil {
		didSet {
			if let asset = asset {
				let source = GLTFSCNSceneSource(asset: asset)
				sceneView.scene = source.defaultScene
				animations = source.animations
				if let defaultAnimation = animations.first {
					defaultAnimation.animationPlayer.animation.usesSceneTimeBase = false
					defaultAnimation.animationPlayer.animation.repeatCount = .greatestFiniteMagnitude
					sceneView.scene?.rootNode.addAnimationPlayer(defaultAnimation.animationPlayer, forKey: nil)
					defaultAnimation.animationPlayer.play()
				}
				sceneView.scene?.rootNode.addChildNode(cameraNode)
				stopActivity()
			}
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.view.addSubview(sceneView)
		sceneView.translatesAutoresizingMaskIntoConstraints = false
		sceneView.allowsCameraControl = true
		sceneView.autoenablesDefaultLighting = true
		sceneView.backgroundColor = .colorNamed("BGFullNFT")
		
		self.view.addSubview(fullScreenButton)
		fullScreenButton.translatesAutoresizingMaskIntoConstraints = false
		fullScreenButton.tintColor = .white
		fullScreenButton.addTarget(self, action: #selector(self.fullscreenTapped), for: .touchUpInside)
		fullScreenButton.alpha = 0
		setupEnterFullscreenButton()
		
		
		fullscreenButtonYConstraint = fullScreenButton.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 8)
		NSLayoutConstraint.activate([
			sceneView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
			sceneView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
			sceneView.topAnchor.constraint(equalTo: self.view.topAnchor),
			sceneView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
			
			fullscreenButtonYConstraint,
			fullScreenButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 8),
			fullScreenButton.widthAnchor.constraint(equalToConstant: 40),
			fullScreenButton.heightAnchor.constraint(equalToConstant: 40),
		])
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(true)
		
		if previousSuperView == nil {
			previousSuperView = self.view.superview
			setupActivity()
		}
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		showControlButtons()
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		startControlButtonTimer()
	}
	
	func setupActivity() {
		activityIndicator.color = .white
		activityIndicator.startAnimating()
		activityIndicator.center = self.view.center
		self.sceneView.addSubview(activityIndicator)
	}
	
	func stopActivity() {
		DispatchQueue.main.async { [weak self] in
			self?.activityIndicator.stopAnimating()
			self?.activityIndicator.removeFromSuperview()
		}
	}
	
	func setupEnterFullscreenButton() {
		fullScreenButton.setImage(UIImage(systemName: "arrow.up.left.and.arrow.down.right"), for: .normal)
		isFullscreen = false
		fullscreenButtonYConstraint.constant = 8
		view.layoutIfNeeded()
	}
	
	func expandToFullScreen() {
		guard let currentWindow = UIApplication.shared.currentWindow else {
			return
		}
		
		// Move view to window and making sure its set to the same position
		globalPoint = self.view.superview?.convert(self.view.frame.origin, to: nil) ?? CGPoint(x: -1, y: -1)
		currentWindow.addSubview(self.view)
		self.view.frame = CGRect(x: globalPoint.x, y: globalPoint.y, width: self.view.frame.width, height: self.view.frame.height)
		self.view.layoutIfNeeded()
		
		// Animate size change
		setupActivity()
		UIView.animate(withDuration: 0.3) { [weak self] in
			self?.sceneView.alpha = 0
			
		} completion: { [weak self] _ in
			UIView.animate(withDuration: 0.3) { [weak self] in
				self?.view.frame = currentWindow.bounds
				self?.view.layoutIfNeeded()
				
			} completion: { [weak self] _ in
				UIView.animate(withDuration: 0.3) { [weak self] in
					self?.sceneView.alpha = 1
					self?.activityIndicator.alpha = 0
					
				} completion: { [weak self] _ in
					self?.stopActivity()
				}
			}
		}
	}
	
	func setupExitFullScreenButton() {
		guard let currentWindow = UIApplication.shared.currentWindow else {
			return
		}
		
		fullScreenButton.setImage(UIImage(systemName: "xmark"), for: .normal)
		isFullscreen = true
		fullscreenButtonYConstraint.constant = (currentWindow.safeAreaInsets.top + 8)
		view.layoutIfNeeded()
	}
	
	func exitFullScreenMode() {
		guard let previousSuperView = previousSuperView else {
			return
		}
		
		// Animate size change
		setupActivity()
		UIView.animate(withDuration: 0.3) { [weak self] in
			self?.sceneView.alpha = 0
			
		} completion: { [weak self] _ in
			UIView.animate(withDuration: 0.3) { [weak self] in
				self?.view.frame = CGRect(x: self?.globalPoint.x ?? 0, y: self?.globalPoint.y ?? 0, width: previousSuperView.frame.size.width, height: previousSuperView.frame.size.height)
				self?.view.layoutIfNeeded()
				
			} completion: { [weak self] _ in
				UIView.animate(withDuration: 0.3) { [weak self] in
					self?.sceneView.alpha = 1
					self?.activityIndicator.alpha = 0
					
				} completion: { [weak self] _ in
					self?.stopActivity()
					
					// Re-add to super view container
					previousSuperView.addSubview(self?.view ?? UIView())
					self?.view.frame = previousSuperView.bounds
					self?.view.layoutIfNeeded()
				}
			}
		}
	}
	
	@objc func fullscreenTapped() {
		if isFullscreen {
			setupEnterFullscreenButton()
			exitFullScreenMode()
		} else {
			setupExitFullScreenButton()
			expandToFullScreen()
		}
	}
	
	func showControlButtons() {
		UIView.animate(withDuration: 0.3) { [weak self] in
			self?.fullScreenButton.alpha = 1
		}
	}
	
	func startControlButtonTimer() {
		controlButtonDisplayTimer?.invalidate()
		controlButtonDisplayTimer = nil
		controlButtonDisplayTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false, block: { [weak self] _ in
			self?.hideControlButtons()
		})
	}
	
	func hideControlButtons() {
		UIView.animate(withDuration: 0.3) { [weak self] in
			self?.fullScreenButton.alpha = 0
		}
		
		controlButtonDisplayTimer?.invalidate()
		controlButtonDisplayTimer = nil
	}
	
	public func setAssetUrl(_ url: URL?) {
		guard let url = url else {
			return
		}
		
		DiskService.fetchRemoteFile(url: url, storeInFolder: "models") { [weak self] result in
			guard let res = try? result.get() else {
				self?.delegate?.threeDimensionModelLoadingError(try? result.getError())
				return
			}
			
			GLTFAsset.load(with: res, options: [:]) { [weak self] progress, status, asset, error, _ in
				if let err = error {
					self?.delegate?.threeDimensionModelLoadingError(err)
				} else {
					self?.asset = asset
				}
			}
		}
	}
}
