//
//  GradientView.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 23/07/2024.
//

import UIKit

class GradientView: UIView {
	private let gradient: CAGradientLayer = CAGradientLayer()
	private var colors: [CGColor] = []
	private var locations: [CGFloat] = []
	private var degrees: CGFloat = 0
	
	var gradientType: GradientType = .fullScreenBackground {
		didSet {
			self.setup()
		}
	}
	
	// MARK: - types
	
	public enum GradientType {
		case fullScreenBackground
		case modalBackground
		case tableViewCell
		case tableViewCellUnconfirmed
		case tableViewCellFailed
	}
	
	
	
	// MARK: - Init
	
	init(gradientType: GradientType) {
		self.gradientType = gradientType
		super.init(frame: .zero)
		
		self.setup()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	static func add(toView: UIView, withType: GradientType) {
		let newGradientView = GradientView(gradientType: withType)
		newGradientView.frame = toView.bounds
		
		toView.addSubview(newGradientView)
		toView.sendSubviewToBack(newGradientView)
		
		NSLayoutConstraint.activate([
			newGradientView.leadingAnchor.constraint(equalTo: toView.leadingAnchor),
			newGradientView.trailingAnchor.constraint(equalTo: toView.trailingAnchor),
			newGradientView.topAnchor.constraint(equalTo: toView.topAnchor),
			newGradientView.bottomAnchor.constraint(equalTo: toView.bottomAnchor)
		])
	}
	
	
	
	// MARK: - Lifecycle
	
	override func layoutSublayers(of layer: CALayer) {
		super.layoutSublayers(of: layer)
		gradient.frame = self.bounds
	}
	
	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		updateColors()
		gradient.colors = self.colors
	}
	
	override public func draw(_ rect: CGRect) {
		gradient.frame = self.bounds
		gradient.colors = self.colors
		gradient.calculatePoints(for: self.degrees)
		
		if gradient.superlayer == nil {
			layer.insertSublayer(gradient, at: 0)
		}
	}
	
	private func setup() {
		self.backgroundColor = .clear
		self.updateColors()
		
		switch gradientType {
			case .fullScreenBackground:
				self.locations = [0.01, 0.34, 0.74]
				self.degrees = cssDegreesToIOS(170)
				self.customCornerRadius = 0
				self.maskToBounds = false
				self.borderWidth = 0
				
			case .modalBackground:
				self.locations = [0.03, 0.50, 0.94]
				self.degrees = cssDegreesToIOS(170)
				self.customCornerRadius = 0
				self.maskToBounds = false
				self.borderWidth = 0
				
			case .tableViewCell:
				self.locations = [0.26, 0.67]
				self.degrees = cssDegreesToIOS(172.5)
				self.customCornerRadius = 8
				self.maskToBounds = true
				self.borderWidth = 0
				
			case .tableViewCellUnconfirmed:
				self.locations = [0.01, 0.93]
				self.degrees = cssDegreesToIOS(90.36)
				self.customCornerRadius = 8
				self.maskToBounds = true
				self.borderWidth = 0
				
			case .tableViewCellFailed:
				self.locations = [0.01, 0.93]
				self.degrees = cssDegreesToIOS(90.36)
				self.customCornerRadius = 8
				self.maskToBounds = true
				self.borderWidth = 0
		}
	}
	
	private func updateColors() {
		switch gradientType {
			case .fullScreenBackground:
				self.colors = [UIColor.colorNamed("gradBgFull-1").cgColor, UIColor.colorNamed("gradBgFull-2").cgColor, UIColor.colorNamed("gradBgFull-3").cgColor]
			
			case .modalBackground:
				self.colors = [UIColor.colorNamed("gradModal-1").cgColor, UIColor.colorNamed("gradModal-2").cgColor, UIColor.colorNamed("gradModal-3").cgColor]
				
			case .tableViewCell:
				self.colors = [UIColor.colorNamed("gradPanelRows-1").cgColor, UIColor.colorNamed("gradPanelRows-2").cgColor]
				
			case .tableViewCellUnconfirmed:
				self.colors = [UIColor.colorNamed("gradUnconfirmed-1").cgColor, UIColor.colorNamed("gradUnconfirmed-2").cgColor]
				
			case .tableViewCellFailed:
				self.colors = [UIColor.colorNamed("gradPanelRows_Alert-1").cgColor, UIColor.colorNamed("gradPanelRows_Alert-2").cgColor]
		}
	}
}
