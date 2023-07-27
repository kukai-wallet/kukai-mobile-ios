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
	
	public weak var delegate: DiscoverFeaturedCellDelegate? = nil
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		collectionView.dataSource = self
		collectionView.delegate = self
		
		let flowLayout = (self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout)
		flowLayout?.minimumLineSpacing = 0
		flowLayout?.minimumInteritemSpacing = 0
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		(self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize = CGSize(width: collectionView.frame.size.width, height: collectionView.frame.size.height)
	}
	
	func setup(discoverGroup: DiscoverGroup, startIndex: Int) {
		self.discoverGroup = discoverGroup
		
		self.collectionView.reloadData()
		self.collectionView.scrollToItem(at: IndexPath(row: startIndex, section: 0), at: .centeredHorizontally, animated: false)
		self.pageControl.numberOfPages = discoverGroup.items.count
		self.pageControl.currentPage = startIndex
		
		if discoverGroup.items.count > 1 {
			stopTimer()
			setupTimer()
		}
	}
	
	public func setupTimer() {
		timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: { [weak self] timer in
			var nextRow = self?.pageControl.currentPage ?? 0
			if nextRow == ((self?.pageControl.numberOfPages ?? 1) - 1) {
				nextRow = -1
			}
			
			self?.collectionView.scrollToItem(at: IndexPath(row: nextRow+1, section: 0), at: .centeredHorizontally, animated: true)
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
		return discoverGroup.items.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DiscoverFeaturedItemCell", for: indexPath) as? DiscoverFeaturedItemCell else {
			return UICollectionViewCell()
		}
		
		let item = discoverGroup.items[indexPath.row]
		cell.setup(categories: [" "], imageURL: item.imageUri, title: item.title, description: item.description, pageWidth: collectionView.frame.width)
		
		return cell
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		delegate?.innerCellTapped(url: discoverGroup.items[indexPath.row].projectURL)
	}
	
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		let pageWidth = collectionView.frame.width
		self.pageControl.currentPage = Int((scrollView.contentOffset.x + pageWidth / 2) / pageWidth)
	}
	
	func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
		self.stopTimer()
	}
	
	func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
		self.setupTimer()
	}
}
