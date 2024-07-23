//
//  UITableViewCell+gradient.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 08/12/2022.
//

import UIKit
import SDWebImage

protocol UITableViewCellImageDownloading {
	func downloadingImageViews() -> [SDAnimatedImageView]
}
