//
//  CMTime+extensions.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 05/01/2023.
//

import CoreMedia

extension CMTime {
	
	var durationText:String {
		let totalSeconds = Int(CMTimeGetSeconds(self))
		let hours:Int = Int(totalSeconds / 3600)
		let minutes:Int = Int(totalSeconds % 3600 / 60)
		let seconds:Int = Int((totalSeconds % 3600) % 60)
		
		if hours > 0 {
			return String(format: "%i:%02i:%02i", hours, minutes, seconds)
		} else {
			return String(format: "%02i:%02i", minutes, seconds)
		}
	}
}
