//
//  TextFieldSuggestionAccessoryView.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 06/04/2023.
//

import UIKit

protocol TextFieldSuggestionAccessoryViewDelegate: AnyObject {
	func didTapSuggestion(suggestion: String)
}

class TextFieldSuggestionAccessoryView: UIView, UICollectionViewDataSource, UICollectionViewDelegate {
	
	private let collectionView: UICollectionView
	private let suggestions: [String]
	private var filteredSuggestions: [String] = []
	
	public weak var delegate: TextFieldSuggestionAccessoryViewDelegate? = nil
	
	public init(withSuggestions: [String]) {
		self.suggestions = withSuggestions
		self.filteredSuggestions = []
		
		let tempFrame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50)
		let flowLayout = UICollectionViewFlowLayout()
		flowLayout.scrollDirection = .horizontal
		flowLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
		
		collectionView = UICollectionView(frame: tempFrame, collectionViewLayout: flowLayout)
		collectionView.backgroundColor = .colorNamed("BG3")
		
		super.init(frame: tempFrame)
		
		self.setup()
	}
	
	required init?(coder: NSCoder) {
		self.suggestions = []
		
		let tempFrame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50)
		let flowLayout = UICollectionViewFlowLayout()
		flowLayout.scrollDirection = .horizontal
		collectionView = UICollectionView(frame: tempFrame, collectionViewLayout: flowLayout)
		
		super.init(coder: coder)
		
		self.setup()
	}
	
	private func setup() {
		self.backgroundColor = .clear
		
		collectionView.translatesAutoresizingMaskIntoConstraints = false
		collectionView.register(UINib(nibName: "TextFieldSuggestionAccessoryViewCell", bundle: nil), forCellWithReuseIdentifier: "TextFieldSuggestionAccessoryViewCell")
		collectionView.dataSource = self
		collectionView.delegate = self
		collectionView.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
		
		self.addSubview(collectionView)
		NSLayoutConstraint.activate([
			collectionView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
			collectionView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
			collectionView.topAnchor.constraint(equalTo: self.topAnchor),
			collectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
		])
	}
	
	public func filterSuggestions(withInput: String?) {
		guard let input = withInput, input != "" else {
			filteredSuggestions = []
			collectionView.reloadData()
			return
		}
		
		DispatchQueue.global(qos: .background).async { [weak self] in
			self?.filteredSuggestions = (self?.suggestions ?? []).filter { $0.hasPrefix(input) }
			
			DispatchQueue.main.async {
				self?.collectionView.reloadData()
			}
		}
	}
	
	
	
	// MARK: - CollectionView
	
	func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 1
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return self.filteredSuggestions.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TextFieldSuggestionAccessoryViewCell", for: indexPath) as? TextFieldSuggestionAccessoryViewCell, indexPath.row < filteredSuggestions.count else {
			return UICollectionViewCell()
		}
		
		cell.setup(withSuggestion: self.filteredSuggestions[indexPath.row])
		return cell
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		delegate?.didTapSuggestion(suggestion: self.filteredSuggestions[indexPath.row])
	}
}
