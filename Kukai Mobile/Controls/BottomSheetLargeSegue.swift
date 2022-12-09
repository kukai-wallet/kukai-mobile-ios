//
//  BottomSheetLargeSegue.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 21/12/2021.
//

import UIKit

public class BottomSheetLargeSegue: UIStoryboardSegue {
	
	override public func perform() {
		guard let dest = destination.presentationController as? UISheetPresentationController else {
			return
		}
		
		dest.detents = [.large()]
		dest.prefersGrabberVisible = true
		dest.preferredCornerRadius = 30
		
		source.present(destination, animated: true)
	}
}
