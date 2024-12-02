//
//  SlideSegue.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 28/11/2024.
//

import UIKit

class SlideSegue: UIStoryboardSegue {
	
	override func perform() {
		let transition: CATransition = CATransition()
		transition.duration = 0.3
		transition.type = CATransitionType.push
		transition.subtype = UIApplication.shared.userInterfaceLayoutDirection == UIUserInterfaceLayoutDirection.rightToLeft ? .fromLeft : .fromRight
		
		source.navigationController?.view.layer.add(transition, forKey: nil)
		source.navigationController?.pushViewController(destination, animated: false)
	}
}
