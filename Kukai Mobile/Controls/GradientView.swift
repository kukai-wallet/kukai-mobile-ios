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
		case panelRow
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
		toView.addSubview(newGradientView)
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
				
			case .panelRow:
				self.locations = [0.26, 0.67]
				self.degrees = cssDegreesToIOS(92.91)
				self.customCornerRadius = 8
				self.maskToBounds = true
				self.borderWidth = 0
		}
	}
	
	private func updateColors() {
		switch gradientType {
			case .fullScreenBackground:
				self.colors = [UIColor.colorNamed("gradBgFull-1").cgColor, UIColor.colorNamed("gradBgFull-2").cgColor, UIColor.colorNamed("gradBgFull-3").cgColor]
				
			case .panelRow:
				self.colors = [UIColor.colorNamed("gradPanelRows-1").cgColor, UIColor.colorNamed("gradPanelRows-2").cgColor]
		}
	}
}
