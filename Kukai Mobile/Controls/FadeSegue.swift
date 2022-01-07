//
//  FadeSegue.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 05/01/2022.
//

import UIKit

public class FadeSegue: UIStoryboardSegue {
	
	override public func perform() {
		let transition: CATransition = CATransition()
		transition.duration = 0.3
		transition.type = CATransitionType.fade
		
		source.navigationController?.view.layer.add(transition, forKey: nil)
		source.navigationController?.pushViewController(destination, animated: false)
	}
}
