//
//  DiscoverFeaturedCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 25/07/2023.
//

import UIKit
import KukaiCoreSwift

protocol DiscoverFeaturedCellDelegate: AnyObject {
	func innerCellTapped(url: URL?)
	func timerSetup(timer: Timer?, sender: DiscoverFeaturedCell)
}

class DiscoverFeaturedCell: UITableViewCell {
	
	@IBOutlet weak var collectionView: UICollectionView!
	@IBOutlet weak var pageControl: UIPageControl!
	
	private var discoverGroup: DiscoverGroup = DiscoverGroup(id: UUID(), title: "", items: [])
	private var timer: Timer? = nil
	private let pageWidth: CGFloat = UIScreen.main.bounds.width
	private var pageHeight: CGFloat = 0
	private var customAspectRatioLogicHasBeenRun = false
	private static let estimatedTextHeight: CGFloat = 40
	private static let estimatedPageControlSize: CGFloat = 30
	private var once = false
	private var selectedIndex = 0
	
	public weak var delegate: DiscoverFeaturedCellDelegate? = nil
	public static let customAspectRatio: CGFloat = 2.62
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		collectionView.accessibilityIdentifier = "discover-featured-cell"
		pageControl.accessibilityIdentifier = "discover-featured-page-control"
		
		collectionView.dataSource = self
		collectionView.delegate = self
		
		let flowLayout = (self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout)
		flowLayout?.minimumLineSpacing = 0
		flowLayout?.minimumInteritemSpacing = 0
	}
	
	/**
	 This cell has very custom aspect ratio sizing business logic, that can't be done via interface builder.
	 Also couldn't find an easy way to calcualte the actual sizes of other ocmponents, for now just hardcode to known values, can revisit late rif it becomes an issue
	 */
	static func featuredCellCustomHeight() -> CGFloat {
		let screenWidth = UIScreen.main.bounds.width
		let newHeight = Decimal(screenWidth/DiscoverFeaturedCell.customAspectRatio).rounded(scale: 0, roundingMode: .up).intValue()
		return CGFloat(newHeight) + DiscoverFeaturedCell.estimatedTextHeight + DiscoverFeaturedCell.estimatedPageControlSize
	}
	
	override func layoutSubviews() {
		if !customAspectRatioLogicHasBeenRun {
			customAspectRatioLogicHasBeenRun = true
			
			let newHeight = Decimal(pageWidth/DiscoverFeaturedCell.customAspectRatio).rounded(scale: 0, roundingMode: .up).intValue()
			pageHeight = CGFloat(newHeight)
			(self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize = CGSize(width: pageWidth, height: pageHeight + DiscoverFeaturedCell.estimatedTextHeight)
		}
		
		super.layoutSubviews()
	}
	
	func setup(discoverGroup: DiscoverGroup) {
		self.discoverGroup = discoverGroup
		
		self.collectionView.reloadData()
		self.pageControl.numberOfPages = discoverGroup.items.count
		self.pageControl.currentPage = 0
		self.once = false
		
		if discoverGroup.items.count > 1 {
			stopTimer()
			setupTimer()
		}
	}
	
	public func setupTimer() {
		stopTimer()
		timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: { [weak self] timer in
			let itemCount = self?.discoverGroup.items.count ?? 0
			var nextRow = (self?.selectedIndex ?? 0) + 1
			if nextRow == (itemCount * 20) {
				nextRow = (itemCount * 10)
			}
			
			self?.collectionView.isPagingEnabled = false // bug fix, some devices don't scroll horizontally if paging enabled for some reason
			self?.collectionView.scrollToItem(at: IndexPath(row: nextRow, section: 0), at: .centeredHorizontally, animated: true)
			self?.collectionView.isPagingEnabled = true
		})
		
		delegate?.timerSetup(timer: timer, sender: self)
	}
	
	public func stopTimer() {
		timer?.invalidate()
		timer = nil
	}
}

extension DiscoverFeaturedCell: UICollectionViewDelegate, UICollectionViewDataSource {
	
	func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 1
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return discoverGroup.items.count * 10_000 // high number to give the appearence of infinite scroll
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DiscoverFeaturedItemCell", for: indexPath) as? DiscoverFeaturedItemCell else {
			return UICollectionViewCell()
		}
		
		let item = discoverGroup.items[indexPath.row % discoverGroup.items.count]
		cell.setup(categories: [" "], title: item.title, description: item.description, pageWidth: pageWidth)
		
		return cell
	}
	
	func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		if !once {
			let infiniteScrollStartIndex = 0 + (discoverGroup.items.count * 10) // give an infinite scroll-like experience by starting off many rows into the the set to allow side ways scrolling
			
			self.collectionView.isPagingEnabled = false // bug fix, some devices don't scroll horizontally if paging enabled for some reason
			self.collectionView.scrollToItem(at: IndexPath(row: infiniteScrollStartIndex, section: 0), at: .centeredHorizontally, animated: false)
			self.collectionView.isPagingEnabled = true
			
			self.once = true
		}
		
		guard let c = cell as? DiscoverFeaturedItemCell else { return }
		
		selectedIndex = indexPath.row
		let item = discoverGroup.items[indexPath.row % discoverGroup.items.count]
		c.setupImage(imageURL: item.featuredItemURL)
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		delegate?.innerCellTapped(url: discoverGroup.items[indexPath.row].projectUrl)
	}
	
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		self.pageControl.currentPage = Int((scrollView.contentOffset.x + pageWidth / 2) / pageWidth) % discoverGroup.items.count
	}
	
	func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
		self.stopTimer()
	}
	
	func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
		self.setupTimer()
	}
}
