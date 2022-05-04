//
//  HomeTabBarController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 20/07/2021.
//

import UIKit
import Combine

class HomeTabBarController: UITabBarController {
	
	@IBOutlet weak var accountButtonParent: UIBarButtonItem!
	@IBOutlet weak var accountButton: UIButton!
	@IBOutlet weak var sendButton: UIButton!
	
	private var walletChangeCancellable: AnyCancellable?
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		walletChangeCancellable = DependencyManager.shared.$walletDidChange
			.dropFirst()
			.sink { [weak self] _ in
				self?.updateAccountButton()
			}
		
		accountButton.titleLabel?.numberOfLines = 2
		accountButton.titleLabel?.lineBreakMode = .byTruncatingMiddle
		accountButton.addConstraint(NSLayoutConstraint(item: accountButton as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: (self.view.frame.width * 0.75)))
		
		sendButton.addConstraint(NSLayoutConstraint(item: sendButton as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 34))
		sendButton.addConstraint(NSLayoutConstraint(item: sendButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 34))
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.navigationController?.setNavigationBarHidden(false, animated: false)
		self.navigationItem.hidesBackButton = true
		
		TransactionService.shared.resetState()
		updateAccountButton()
	}
	
	public func updateAccountButton() {
		guard let wallet = DependencyManager.shared.selectedWallet else {
			return
		}
		
		accountButton.setImage((wallet.type == .torus) ? UIImage(systemName: "xmark.octagon") : UIImage(), for: .normal)
		accountButton.setTitle("Wallet Type: \(wallet.type.rawValue)\n\(wallet.address)", for: .normal)
	}
	
	@IBAction func sendButtonTapped(_ sender: Any) {
		self.performSegue(withIdentifier: "send", sender: nil)
	}
	
	
	
	
	
	
	
	
	
	/*
	 // Prevent nav button from consuming the entire nav bar
	 //accountNavButton.addConstraint(NSLayoutConstraint(item: accountNavButton as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 140))
	 
	 
	 
	 
	 
	private let middleButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
	 
	 
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.navigationController?.setNavigationBarHidden(true, animated: false)
		self.navigationItem.hidesBackButton = true
		
		guard let tabItems = tabBar.items else { return }
		tabItems[0].titlePositionAdjustment = UIOffset(horizontal: -25, vertical: 0)
		tabItems[1].titlePositionAdjustment = UIOffset(horizontal: 25, vertical: 0)
		
		middleButton.setBackgroundImage(UIImage(named: "middle-tab-button"), for: .normal)
		middleButton.setBackgroundImage(UIImage(named: "middle-tab-button")?.maskWithColor(color: .lightGray), for: .highlighted)
		middleButton.tintColor = UIColor.black
		middleButton.center = CGPoint(x: tabBar.frame.width/2, y: 25)
		self.tabBar.addSubview(middleButton)
		
		self.view.backgroundColor = UIColor(named: "background")
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		self.tabBar.roundCorners(corners: [.topLeft, .topRight], radius: 28)
	}
	*/
}
