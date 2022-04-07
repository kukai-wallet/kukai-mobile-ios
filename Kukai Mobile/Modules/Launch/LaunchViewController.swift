//
//  LaunchViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 15/07/2021.
//

import UIKit
import KukaiCoreSwift

class LaunchViewController: UIViewController, CAAnimationDelegate {
	
	@IBOutlet weak var kukaiLogo: UIImageView!
	@IBOutlet weak var safeImage: UIImageView!
	@IBOutlet weak var kukaiTextImage: UIImageView!
	@IBOutlet weak var kukaiTextCoverView: UIView!
	@IBOutlet weak var constraintKukaiLogoXCenter: NSLayoutConstraint!
	@IBOutlet weak var constraintKukaiLogoYCenter: NSLayoutConstraint!
	@IBOutlet weak var constraintKukaiTextX: NSLayoutConstraint!
	@IBOutlet weak var constraintKukaiTextY: NSLayoutConstraint!
	
	private var transformToLeft: CATransform3D? = nil
	private var transformToRight: CATransform3D? = nil
	
	private let safeDoorAnimationDuration = 1.0
	private var safeAnimations: [CABasicAnimation] = []
	private var coverAnimations: [CABasicAnimation] = []
	private var textAnimations: [CABasicAnimation] = []
	
	private var leftSafePosition = CGPoint(x: 0, y: 0)
	private var rightTextPosition = CGPoint(x: 0, y: 0)
	private var readyToShrinkSafe = false
	private var readyToShrinkText = false
	private var runOnce = false // TODO:
	
	private let cloudKitService = CloudKitService()
	private var dispatchGroup = DispatchGroup()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		if !runOnce {
			setAnchorPoint(anchorPoint: CGPoint(x: 1, y: 0.5), forView: kukaiLogo)
			kukaiLogo.layer.zPosition = 10000
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		dispatchGroup = DispatchGroup()
		dispatchGroup.enter() // cloud config to download
		dispatchGroup.enter() // animation to finish
		
		// Check to see if we need to fetch torus verfier config
		if DependencyManager.shared.torusVerifiers.keys.count == 0 {
			cloudKitService.fetchConfigItems { [weak self] error in
				if let e = error {
					self?.alert(errorWithMessage: "Unable to fetch config settings: \(e)")
					
				} else {
					DependencyManager.shared.torusVerifiers = self?.cloudKitService.extractTorusConfig(testnet: true) ?? [:]
					
					print("Verifiers: \n\(DependencyManager.shared.torusVerifiers) \n\n")
				}
				
				self?.dispatchGroup.leave()
			}
		}
		
		// Check if we need to run the animation
		if !runOnce {
			leftSafePosition = CGPoint(x: kukaiLogo.center.x - 180, y: kukaiLogo.center.y)
			rightTextPosition = CGPoint(x: kukaiTextImage.center.x + 80, y: kukaiTextImage.center.y)
			openSafeDoor()
			
		} else {
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
				self?.dispatchGroup.leave()
			}
		}
		
		
		// When everything fetched/animated, process data
		dispatchGroup.notify(queue: .main) { [weak self] in
			self?.disolveTransition()
		}
	}
	
	func animationDidStart(_ anim: CAAnimation) {
		guard let id = anim.value(forKey: "animationID") as? String else {
			return
		}
		
		if id == "moveSafeLeft" {
			applyNextTextAnimation()
			applyNextCoverAnimation()
		}
	}
	
	func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
		guard let id = anim.value(forKey: "animationID") as? String else {
			return
		}
		
		if id == "openSafe", let transform = transformToRight {
			kukaiLogo.layer.transform = transform
			applyNextSafeAnimation()
			
		} else if id == "closeSafe", let transform = transformToLeft {
			kukaiLogo.layer.transform = transform
			safeImage.isHidden = true
			setAnchorPoint(anchorPoint: CGPoint(x: 0.5, y: 0.5), forView: kukaiLogo)
			applyNextSafeAnimation()
			
		} else if id == "growSafe" {
			kukaiLogo.layer.transform = CATransform3DMakeScale(1.1, 1.1, 1.1)
			applyNextSafeAnimation(withDelay: false)
			
		} else if id == "moveSafeLeft" {
			kukaiLogo.center = leftSafePosition
			readyToShrinkSafe = true
			
		} else if id == "rotateSafe" || id == "shrinkSafe" {
			applyNextSafeAnimation()
		}
		
		
		if id == "moveTextRight" {
			kukaiTextCoverView.isHidden = true
			kukaiTextImage.center = rightTextPosition
			readyToShrinkText = true
		}
		
		
		if readyToShrinkSafe && readyToShrinkText {
			applyUniqueShrinkAnimation()
			
			readyToShrinkSafe = false
			readyToShrinkText = false
			
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
				self?.dispatchGroup.leave()
			}
		}
	}
	
	func openSafeDoor() {
		var transformIdentity = CATransform3DIdentity
		transformIdentity.m34 = 1.0 / 500.0;
		
		transformToRight = CATransform3DRotate(transformIdentity, CGFloat(-80 * Double.pi / 180), 0, 1, 0)
		transformToLeft = CATransform3DRotate(transformIdentity, CGFloat(0 * Double.pi / 180), 0, 1, 0)
		
		guard let toRight = transformToRight, let toLeft = transformToLeft else {
			return
		}
		
		
		// Open safe
		let animationOpen = CABasicAnimation(keyPath: "transform")
		animationOpen.setValue("openSafe", forKey: "animationID")
		animationOpen.toValue = NSValue(caTransform3D: toRight)
		animationOpen.duration = safeDoorAnimationDuration
		animationOpen.fillMode = .forwards
		animationOpen.isRemovedOnCompletion = false
		animationOpen.delegate = self
		safeAnimations.append(animationOpen)
		
		// Then close safe
		let animationClose = CABasicAnimation(keyPath: "transform")
		animationClose.setValue("closeSafe", forKey: "animationID")
		animationClose.toValue = NSValue(caTransform3D: toLeft)
		animationClose.fromValue = NSValue(caTransform3D: toRight)
		animationClose.duration = safeDoorAnimationDuration
		animationClose.fillMode = .forwards
		animationClose.isRemovedOnCompletion = false
		animationClose.delegate = self
		safeAnimations.append(animationClose)
		
		
		
		// Spin safe door
		let animationRotate = CABasicAnimation(keyPath: "transform.rotation")
		animationRotate.setValue("rotateSafe", forKey: "animationID")
		animationRotate.fromValue = 0
		animationRotate.toValue = CGFloat.pi * 2
		animationRotate.duration = safeDoorAnimationDuration / 2
		animationRotate.fillMode = .forwards
		animationRotate.isRemovedOnCompletion = false
		animationRotate.delegate = self
		safeAnimations.append(animationRotate)
		
		
		
		// Then grow / shrink quickly
		let animationGrow = CABasicAnimation(keyPath: "transform.scale")
		animationGrow.setValue("growSafe", forKey: "animationID")
		animationGrow.toValue = CATransform3DMakeScale(1.1, 1.1, 1.1)
		animationGrow.duration = 0.1
		animationGrow.fillMode = .forwards
		animationGrow.isRemovedOnCompletion = false
		animationGrow.delegate = self
		safeAnimations.append(animationGrow)
		
		let animationShrink = CABasicAnimation(keyPath: "transform.scale")
		animationShrink.setValue("shrinkSafe", forKey: "animationID")
		animationShrink.toValue = CATransform3DMakeScale(1, 1, 1)
		animationShrink.duration = 0.1
		animationShrink.fillMode = .forwards
		animationShrink.isRemovedOnCompletion = false
		animationShrink.delegate = self
		safeAnimations.append(animationShrink)
		
		
		
		// The move safe + text cover left, move text right
		let animateLeft = CABasicAnimation(keyPath: "position")
		let toLeftRect = leftSafePosition
		animateLeft.setValue("moveSafeLeft", forKey: "animationID")
		animateLeft.toValue = NSValue(cgPoint: toLeftRect)
		animateLeft.duration = safeDoorAnimationDuration / 2
		animateLeft.fillMode = .forwards
		animateLeft.isRemovedOnCompletion = false
		animateLeft.delegate = self
		safeAnimations.append(animateLeft)
		
		let animateCoverLeft = CABasicAnimation(keyPath: "position")
		let toLeftRect2 = CGPoint(x: kukaiTextCoverView.center.x - 200, y: kukaiLogo.center.y)
		animateCoverLeft.setValue("moveCoverLeft", forKey: "animationID")
		animateCoverLeft.toValue = NSValue(cgPoint: toLeftRect2)
		animateCoverLeft.duration = safeDoorAnimationDuration / 2
		animateCoverLeft.fillMode = .forwards
		animateCoverLeft.isRemovedOnCompletion = false
		animateCoverLeft.delegate = self
		coverAnimations.append(animateCoverLeft)
		
		let animateTextRight = CABasicAnimation(keyPath: "position")
		let toRightRect = rightTextPosition
		animateTextRight.setValue("moveTextRight", forKey: "animationID")
		animateTextRight.toValue = NSValue(cgPoint: toRightRect)
		animateTextRight.duration = safeDoorAnimationDuration / 2
		animateTextRight.fillMode = .forwards
		animateTextRight.isRemovedOnCompletion = false
		animateTextRight.delegate = self
		textAnimations.append(animateTextRight)
		
		applyNextSafeAnimation()
	}
	
	func applyNextSafeAnimation(withDelay: Bool = true) {
		if safeAnimations.count == 0 { return }
		
		if let animation = safeAnimations.first {
			safeAnimations.removeFirst()
			
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
				self?.kukaiLogo.layer.add(animation, forKey: "transform")
			}
		}
	}
	
	func applyNextCoverAnimation() {
		if coverAnimations.count == 0 { return }
		
		if let animation = coverAnimations.first {
			coverAnimations.removeFirst()
			kukaiTextCoverView.layer.add(animation, forKey: "transform")
		}
	}
	
	func applyNextTextAnimation() {
		if textAnimations.count == 0 { return }
		
		if let animation = textAnimations.first {
			textAnimations.removeFirst()
			kukaiTextImage.layer.add(animation, forKey: "transform")
		}
	}
	
	func applyUniqueShrinkAnimation() {
		
		CATransaction.begin()
		
		// Move up
		let animateUp = CABasicAnimation(keyPath: "position")
		let toUpRect = CGPoint(x: kukaiLogo.center.x + 87, y: kukaiLogo.center.y - 335)
		animateUp.setValue("moveSafeUp", forKey: "animationID")
		animateUp.toValue = NSValue(cgPoint: toUpRect)
		animateUp.duration = 0.6
		animateUp.fillMode = .forwards
		animateUp.isRemovedOnCompletion = false
		kukaiLogo.layer.add(animateUp, forKey: "position")
		
		let animateTextUp = CABasicAnimation(keyPath: "position")
		let toUpTextRect = CGPoint(x: kukaiTextImage.center.x - 34, y: kukaiTextImage.center.y - 335)
		animateTextUp.setValue("moveTextUp", forKey: "animationID")
		animateTextUp.toValue = NSValue(cgPoint: toUpTextRect)
		animateTextUp.duration = 0.6
		animateTextUp.fillMode = .forwards
		animateTextUp.isRemovedOnCompletion = false
		kukaiTextImage.layer.add(animateTextUp, forKey: "position")
		
		
		// Shrink
		let animationShrink2 = CABasicAnimation(keyPath: "transform.scale")
		animationShrink2.setValue("shrinkSafe2", forKey: "animationID")
		animationShrink2.toValue = CATransform3DMakeScale(0.33, 0.33, 0.33)
		animationShrink2.duration = 0.6
		animationShrink2.fillMode = .forwards
		animationShrink2.isRemovedOnCompletion = false
		kukaiLogo.layer.add(animationShrink2, forKey: "transform")
		
		let animationTextShrink = CABasicAnimation(keyPath: "transform.scale")
		animationTextShrink.setValue("shrinkSafe", forKey: "animationID")
		animationTextShrink.toValue = CATransform3DMakeScale(0.33, 0.33, 0.33)
		animationTextShrink.duration = 0.6
		animationTextShrink.fillMode = .forwards
		animationTextShrink.isRemovedOnCompletion = false
		kukaiTextImage.layer.add(animationTextShrink, forKey: "transform")
		CATransaction.commit()
	}
	
	func setAnchorPoint(anchorPoint: CGPoint, forView view: UIView) {
		var newPoint = CGPoint(x: view.bounds.size.width * anchorPoint.x, y: view.bounds.size.height * anchorPoint.y)
		var oldPoint = CGPoint(x: view.bounds.size.width * view.layer.anchorPoint.x, y: view.bounds.size.height * view.layer.anchorPoint.y)
		
		newPoint = newPoint.applying(view.transform)
		oldPoint = oldPoint.applying(view.transform)
		
		var position = view.layer.position
		position.x -= oldPoint.x
		position.x += newPoint.x
		
		position.y -= oldPoint.y
		position.y += newPoint.y
		
		view.layer.position = position
		view.layer.anchorPoint = anchorPoint
	}
	
	func disolveTransition() {
		self.navigationItem.hidesBackButton = true
		self.navigationItem.largeTitleDisplayMode = .never
		
		runOnce = true
		if WalletCacheService().fetchPrimaryWallet() != nil {
			self.performSegue(withIdentifier: "home", sender: nil)
		} else {
			self.performSegue(withIdentifier: "onboarding", sender: nil)
		}
	}
}
