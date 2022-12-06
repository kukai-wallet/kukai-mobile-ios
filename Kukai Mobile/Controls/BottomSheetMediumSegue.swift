//
//  BottomSheetMediumSegue.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 21/12/2021.
//

import UIKit

public class BottomSheetMediumSegue: UIStoryboardSegue {
	
	override public func perform() {
		guard let dest = destination.presentationController as? UISheetPresentationController else {
			return
		}
		
		dest.detents = [.medium()]
		dest.prefersGrabberVisible = true
		dest.preferredCornerRadius = 30
		
		source.present(destination, animated: true)
	}
}
