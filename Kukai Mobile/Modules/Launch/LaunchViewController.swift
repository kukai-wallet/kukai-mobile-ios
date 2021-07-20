//
//  LaunchViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 15/07/2021.
//

import UIKit
import KukaiCoreSwift

class LaunchViewController: UIViewController {

	@IBOutlet weak var tezosImage: UIImageView!
	@IBOutlet weak var safeImage: UIImageView!
	@IBOutlet weak var kukaiLabel: UILabel!
	@IBOutlet weak var kukaiLabelTopConstraint: NSLayoutConstraint!
	
	private var transformToLeft: CATransform3D? = nil
	private var transformToRight: CATransform3D? = nil
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		// Set anchor point of safe image, to the left hand side, so it acts like a door closing
		setAnchorPoint(anchorPoint: CGPoint(x: 0, y: 0.5), forView: safeImage)
		tezosImage.layer.zPosition = -10000
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.navigationController?.setNavigationBarHidden(true, animated: false)
		self.navigationItem.hidesBackButton = true
		
		
		// Start off with safe rotated to left (door open)
		var transformIdentity = CATransform3DIdentity
		transformIdentity.m34 = 1.0 / 500.0;
		
		transformToLeft = CATransform3DRotate(transformIdentity, CGFloat(90 * Double.pi / 180), 0, 1, 0)
		transformToRight = CATransform3DRotate(transformIdentity, CGFloat(0 * Double.pi / 180), 0, 1, 0)
		
		if let toLeft = transformToLeft {
			safeImage.layer.transform = toLeft
		}
		
		// Start with Kuaki text beneath screen
		let roughDistanceToBottom = UIScreen.main.bounds.height / 2
		kukaiLabelTopConstraint.constant = roughDistanceToBottom
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(true)
		
		guard let toRight = transformToRight else {
			return
		}
		
		
		// Animate safe door closing on top of Tezos
		let animation = CABasicAnimation(keyPath: "transform")
		animation.toValue = NSValue(caTransform3D:toRight)
		animation.duration = 1.5
		animation.fillMode = .forwards
		animation.isRemovedOnCompletion = false

		safeImage.layer.add(animation, forKey: "transform")
		
		
		// Animate Kukai text coming in from bottom, when done wait briefly and move to onbaording
		kukaiLabelTopConstraint.constant = 8
		
		UIView.animate(withDuration: 1.5) { [weak self] in
			self?.view.layoutIfNeeded()
		} completion: { success in
			DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
				self?.showNavigationBar()
				
				if WalletCacheService().fetchPrimaryWallet() != nil {
					self?.performSegue(withIdentifier: "home", sender: nil)
				} else {
					self?.performSegue(withIdentifier: "onboarding", sender: nil)
				}
			}
		}
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
	
	func showNavigationBar() {
		self.navigationController?.setNavigationBarHidden(false, animated: false)
		self.navigationItem.hidesBackButton = true
		self.navigationItem.largeTitleDisplayMode = .never
	}
}
