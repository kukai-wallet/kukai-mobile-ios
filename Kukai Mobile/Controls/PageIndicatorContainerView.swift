//
//  PageIndicatorContainerView.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 27/11/2024.
//

import UIKit

public class PageIndicatorContainerView: UIView {
	
	let pagePendingView = UIView()
	let pageInprogressView = UIView()
	let pageNumberLabel = UILabel()
	let pageCompleteView = UIView()
	let checkImageView = UIImageView(image: UIImage(named: "Check"))
	
	public override init(frame: CGRect) {
		super.init(frame: frame)
		setup()
	}
	
	public required init?(coder: NSCoder) {
		super.init(coder: coder)
		setup()
	}
	
	private func setup() {
		self.backgroundColor = .clear
		
		pagePendingView.translatesAutoresizingMaskIntoConstraints = false
		pagePendingView.frame = CGRect(x: 0, y: 0, width: 14, height: 14)
		pagePendingView.backgroundColor = .colorNamed("BG6")
		pagePendingView.customCornerRadius = 7
		self.addSubview(pagePendingView)
		
		pageInprogressView.translatesAutoresizingMaskIntoConstraints = false
		pageInprogressView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
		pageInprogressView.backgroundColor = .colorNamed("BG0")
		pageInprogressView.customCornerRadius = 14
		pageInprogressView.borderColor = .colorNamed("BGB4")
		pageInprogressView.borderWidth = 2
		pageInprogressView.maskToBounds = true
		pageInprogressView.alpha = 0
		
		pageNumberLabel.translatesAutoresizingMaskIntoConstraints = false
		pageNumberLabel.font = .custom(ofType: .medium, andSize: 16)
		pageNumberLabel.textColor = .white
		pageNumberLabel.textAlignment = .center
		pageInprogressView.addSubview(pageNumberLabel)
		self.addSubview(pageInprogressView)
		
		pageCompleteView.translatesAutoresizingMaskIntoConstraints = false
		pageCompleteView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
		pageCompleteView.backgroundColor = .colorNamed("BGB4")
		pageCompleteView.customCornerRadius = 14
		pageCompleteView.alpha = 0
		
		checkImageView.translatesAutoresizingMaskIntoConstraints = false
		checkImageView.tintColor = .white
		pageCompleteView.addSubview(checkImageView)
		self.addSubview(pageCompleteView)
		
		NSLayoutConstraint.activate([
			pagePendingView.widthAnchor.constraint(equalToConstant: 14),
			pagePendingView.heightAnchor.constraint(equalToConstant: 14),
			pagePendingView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
			pagePendingView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
			
			pageInprogressView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
			pageInprogressView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
			pageInprogressView.topAnchor.constraint(equalTo: self.topAnchor),
			pageInprogressView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
			
			pageNumberLabel.leadingAnchor.constraint(equalTo: pageInprogressView.leadingAnchor),
			pageNumberLabel.trailingAnchor.constraint(equalTo: pageInprogressView.trailingAnchor),
			pageNumberLabel.topAnchor.constraint(equalTo: pageInprogressView.topAnchor),
			pageNumberLabel.bottomAnchor.constraint(equalTo: pageInprogressView.bottomAnchor),
			
			pageCompleteView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
			pageCompleteView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
			pageCompleteView.topAnchor.constraint(equalTo: self.topAnchor),
			pageCompleteView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
			
			checkImageView.leadingAnchor.constraint(equalTo: pageCompleteView.leadingAnchor, constant: 2),
			checkImageView.trailingAnchor.constraint(equalTo: pageCompleteView.trailingAnchor, constant: -2),
			checkImageView.topAnchor.constraint(equalTo: pageCompleteView.topAnchor, constant: 2),
			checkImageView.bottomAnchor.constraint(equalTo: pageCompleteView.bottomAnchor, constant: -2),
		])
	}
	
	public func setPending() {
		pagePendingView.alpha = 1
		pageInprogressView.alpha = 0
		pageNumberLabel.alpha = 0
		pageCompleteView.alpha = 0
		checkImageView.alpha = 0
	}
	
	public func setInprogress(pageNumber: Int) {
		pageNumberLabel.text = pageNumber.description
		UIView.animate(withDuration: 0.3) { [weak self] in
			self?.pagePendingView.transform = CGAffineTransform(scaleX: 2, y: 2)
			
		} completion: { [weak self] _ in
			self?.pageCompleteView.alpha = 0
			self?.checkImageView.alpha = 0
		}
		
		UIView.animate(withDuration: 0.3, delay: 0.2) { [weak self] in
			self?.pagePendingView.alpha = 0
			
			self?.pageNumberLabel.alpha = 1
			self?.pageInprogressView.alpha = 1
		}
	}
	
	public func setComplete() {
		UIView.animate(withDuration: 0.3) { [weak self] in
			self?.pageNumberLabel.alpha = 0
			self?.pageCompleteView.alpha = 1
			
		} completion: { _ in
			UIView.animate(withDuration: 0.3) { [weak self] in
				self?.checkImageView.alpha = 1
			}
		}

	}
}
