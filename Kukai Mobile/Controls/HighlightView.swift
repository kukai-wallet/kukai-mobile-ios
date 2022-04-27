//
//  HighlightView.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 27/04/2022.
//

import UIKit

class HighlightView: UIView {
	
	private var nonHighlightColor: UIColor = .clear
	
	public var backgroundHighlightColor: UIColor = .lightGray
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		nonHighlightColor = self.backgroundColor ?? .clear
		
		DispatchQueue.main.async { [weak self] in
			self?.backgroundColor = self?.nonHighlightColor
			UIView.animate(withDuration: 0.4, delay: 0.0, options: .curveLinear, animations: {
				self?.backgroundColor = self?.backgroundHighlightColor
			}, completion: nil)
		}
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		DispatchQueue.main.async { [weak self] in
			self?.backgroundColor = self?.backgroundHighlightColor
			UIView.animate(withDuration: 0.4, delay: 0.0, options: .curveLinear, animations: {
				self?.backgroundColor = self?.nonHighlightColor
			}, completion: nil)
		}
	}
	
	override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
		DispatchQueue.main.async { [weak self] in
			self?.backgroundColor = self?.backgroundHighlightColor
			UIView.animate(withDuration: 0.4, delay: 0.0, options: .curveLinear, animations: {
				self?.backgroundColor = self?.nonHighlightColor
			}, completion: nil)
		}
	}
}
