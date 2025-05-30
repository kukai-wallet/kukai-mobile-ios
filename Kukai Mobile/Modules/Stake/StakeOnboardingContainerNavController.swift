//
//  StakeOnboardingContainerNavController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 29/11/2024.
//

import UIKit

class StakeOnboardingContainerNavController: UINavigationController, BottomSheetCustomCalculateProtocol {
	
	var dimBackground = true
	
	func bottomSheetHeight() -> CGFloat {
		return view.bounds.height * 0.75
	}
}
