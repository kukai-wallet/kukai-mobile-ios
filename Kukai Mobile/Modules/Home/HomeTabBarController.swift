//
//  HomeTabBarController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 20/07/2021.
//

import UIKit

class HomeTabBarController: UITabBarController {
	
	private let middleButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
	
    override func viewDidLoad() {
        super.viewDidLoad()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
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
}
