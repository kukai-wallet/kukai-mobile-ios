//
//  UIButtonImageAboveText.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 21/02/2022.
//

import UIKit

public class UIButtonImageAboveText: UIButton {
	
	/*
	public override func layoutSubviews() {
		super.layoutSubviews()
		
		guard let imageView = self.imageView, let titleLabel = self.titleLabel else {
			return
		}
		
		imageView.removeConstraints(imageView.constraints)
		titleLabel.removeConstraints(titleLabel.constraints)
		
		NSLayoutConstraint.activate([
			imageView.centerXAnchor.constraint(equalTo: self.centerXAnchor, constant: 0),
			imageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 4),
			imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 4),
			imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 4),
			
			titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 4),
			titleLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -4),
			titleLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 4),
			titleLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -4),
		])
	}
	*/
	
	/*
	public override func layoutSubviews() {
		super.layoutSubviews()
		
		let padding = 4
		titleLabel?.frame = CGRect(x: padding, y: self.frame.height - padding, width: self.frame.width - (padding * 2), height: <#T##CGFloat#>)
		
		
		
		let padding: CGFloat = 4
		let iH = imageView?.frame.height ?? 0
		let tH = titleLabel?.frame.height ?? 0
		let v: CGFloat = (frame.height - iH - tH - padding) / 2
		if let iv = imageView {
			let x = (frame.width - iv.frame.width) / 2
			iv.frame.origin.y = v
			iv.frame.origin.x = x
		}
		
		if let tl = titleLabel {
			let x = (frame.width - tl.frame.width) / 2
			tl.frame.origin.y = frame.height - tl.frame.height - v
			tl.frame.origin.x = x
		}
	}
	*/
}
