//
//  CollectiblesCollectionCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/05/2023.
//

import UIKit
import KukaiCoreSwift
import Kingfisher

class CollectiblesCollectionCell: UICollectionViewCell, UITableViewCellImageDownloading {
	
	@IBOutlet weak var collectionIcon: UIImageView!
	@IBOutlet weak var collectionName: UILabel!
	
	@IBOutlet weak var collectionImage1: AnimatedImageView!
	@IBOutlet weak var collectionImage2: AnimatedImageView!
	@IBOutlet weak var collectionImage3: AnimatedImageView!
	@IBOutlet weak var collectionImage4: AnimatedImageView!
	@IBOutlet weak var collectionImage5: AnimatedImageView!
	
	@IBOutlet weak var lastImageTitle: UILabel!
	
	private var gradientLayer: CAGradientLayer? = nil
	private var totalCount: Int?
	private var previousGradientBounds = CGRect.zero
	
	func setup(title: String, totalCount: Int?) {
		self.collectionName.text = title
		self.totalCount = totalCount
		
		collectionIcon.accessibilityIdentifier = "collecibtles-group-icon"
	}
	
	func setup(iconImage: UIImage?, title: String, totalCount: Int?) {
		self.collectionIcon.image = iconImage
		self.collectionName.text = title
		self.totalCount = totalCount
	}
	
	func setupCollectionImage(url: URL?) {
		MediaProxyService.load(url: url, to: collectionIcon, withCacheType: .temporary, fallback: UIImage.unknownToken(), downSampleSize: nil)
	}
	
	func setupImages(imageURLs: [URL?]) {
		
		// Images 1-4 display if urls present
		
		emptyStyle(forImageView: collectionImage1)
		if imageURLs.count > 0 {
			MediaProxyService.load(url: imageURLs[0], to: collectionImage1, withCacheType: .temporary, fallback: UIImage.unknownGroup()) { [weak self] imageSize in
				if imageSize != nil {
					self?.collectionImage1.backgroundColor = .colorNamed("BGThumbNFT")
					self?.collectionImage1.borderWidth = 0
				} else {
					self?.emptyStyle(forImageView: self?.collectionImage1)
				}
			}
		}
		
		emptyStyle(forImageView: collectionImage2)
		if imageURLs.count > 1 {
			MediaProxyService.load(url: imageURLs[1], to: collectionImage2, withCacheType: .temporary, fallback: UIImage.unknownGroup()) { [weak self] imageSize in
				if imageSize != nil {
					self?.collectionImage2.backgroundColor = .colorNamed("BGThumbNFT")
					self?.collectionImage2.borderWidth = 0
				} else {
					self?.emptyStyle(forImageView: self?.collectionImage2)
				}
			}
		}
		
		emptyStyle(forImageView: collectionImage3)
		if imageURLs.count > 2 {
			MediaProxyService.load(url: imageURLs[2], to: collectionImage3, withCacheType: .temporary, fallback: UIImage.unknownGroup()) { [weak self] imageSize in
				if imageSize != nil {
					self?.collectionImage3.backgroundColor = .colorNamed("BGThumbNFT")
					self?.collectionImage3.borderWidth = 0
				} else {
					self?.emptyStyle(forImageView: self?.collectionImage3)
				}
			}
		}
		
		emptyStyle(forImageView: collectionImage4)
		if imageURLs.count > 3 {
			MediaProxyService.load(url: imageURLs[3], to: collectionImage4, withCacheType: .temporary, fallback: UIImage.unknownGroup()) { [weak self] imageSize in
				if imageSize != nil {
					self?.collectionImage4.backgroundColor = .colorNamed("BGThumbNFT")
					self?.collectionImage4.borderWidth = 0
				} else {
					self?.emptyStyle(forImageView: self?.collectionImage4)
				}
			}
		}
		
		
		
		// Image 5 displays a count of how many items left, an image if theres exactly 5, or a blank space like the rest
		
		emptyStyle(forImageView: collectionImage5)
		if let total = totalCount {
			lastImageTitle.text = "+\(total)"
			lastImageTitle.isHidden = false
			
		} else if imageURLs.count > 4 {
			MediaProxyService.load(url: imageURLs[4], to: collectionImage5, withCacheType: .temporary, fallback: UIImage.unknownGroup()) { [weak self] imageSize in
				if imageSize != nil {
					self?.collectionImage5.backgroundColor = .colorNamed("BGThumbNFT")
					self?.collectionImage5.borderWidth = 0
				} else {
					self?.emptyStyle(forImageView: self?.collectionImage5)
				}
			}
			
			lastImageTitle.isHidden = true
			
		} else {
			lastImageTitle.isHidden = true
		}
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		if self.previousGradientBounds.width != self.contentView.bounds.width {
			addGradientBackground() // Strange loading issue. First time it loads these cells, width is 50% of what it should be
		}
	}
	
	public func addGradientBackground() {
		contentView.customCornerRadius = 8
		contentView.maskToBounds = true
		gradientLayer?.removeFromSuperlayer()
		gradientLayer = self.contentView.addGradientPanelRows(withFrame: self.contentView.bounds)
		
		self.previousGradientBounds = self.contentView.bounds
	}
	
	private func emptyStyle(forImageView imageView: UIImageView?) {
		guard let imageView = imageView else { return }
		
		imageView.backgroundColor = .colorNamed("BG3")
		imageView.borderWidth = 1
		imageView.borderColor = .colorNamed("BG2")
	}
	
	override func prepareForReuse() {
		collectionImage1.image = nil
		collectionImage1.backgroundColor = .clear
		collectionImage2.image = nil
		collectionImage2.backgroundColor = .clear
		collectionImage3.image = nil
		collectionImage3.backgroundColor = .clear
		collectionImage4.image = nil
		collectionImage4.backgroundColor = .clear
		collectionImage5.image = nil
		collectionImage5.backgroundColor = .clear
	}
	
	func downloadingImageViews() -> [UIImageView] {
		return [collectionImage1, collectionImage2, collectionImage3, collectionImage4, collectionImage5]
	}
}
