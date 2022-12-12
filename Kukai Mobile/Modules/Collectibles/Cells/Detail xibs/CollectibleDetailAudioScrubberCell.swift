//
//  CollectibleDetailAudioScrubberCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 28/11/2022.
//

import UIKit
import AVKit

class CollectibleDetailAudioScrubberCell: UICollectionViewCell {

	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	@IBOutlet weak var button: UIButton!
	@IBOutlet weak var slider: UISlider!
	
	private var isPlaying = false
	private var avPlayer: AVPlayer = AVPlayer()
	private var playbackLikelyToKeepUpContext = 0
	private var periodicTimeObserver: Any? = nil
	
	override func awakeFromNib() {
        super.awakeFromNib()
    }
	
	func setup(withURL: URL?) {
		button.isHidden = true
		slider.isHidden = true
		slider.value = 0
		activityIndicator.startAnimating()
		
		guard let url = withURL else {
			return
		}
		
		avPlayer = AVPlayer(url: url)
		avPlayer.addObserver(self, forKeyPath: "currentItem.playbackLikelyToKeepUp", options: .new, context: &playbackLikelyToKeepUpContext)
		periodicTimeObserver = avPlayer.addPeriodicTimeObserver(forInterval: .init(seconds: 1, preferredTimescale: 1), queue: nil) { [weak self] time in
			guard self?.slider.isTracking == false else { return }
			
			//if slider is not being touched, then update the slider from here
			self?.updateSlider(with: time)
		}
	}
	
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		if context == &playbackLikelyToKeepUpContext {
			if avPlayer.currentItem!.isPlaybackLikelyToKeepUp {
				activityIndicator.stopAnimating()
				activityIndicator.isHidden = true
				
				button.isHidden = false
				slider.isHidden = false
				slider.minimumValue = 0
				slider.maximumValue = Float(CMTimeGetSeconds(avPlayer.currentItem?.duration ?? CMTime()))
				
			} else {
				activityIndicator.startAnimating()
				activityIndicator.isHidden = false
			}
		}
	}
	
	func updateSlider(with: CMTime) {
		slider.value = Float(CMTimeGetSeconds(avPlayer.currentItem?.currentTime() ?? CMTime()))
	}
	
	@IBAction func buttonTapped(_ sender: Any) {
		if !isPlaying {
			button.setImage(UIImage(systemName: "pause.fill"), for: .normal)
			avPlayer.play()
			
		} else {
			button.setImage(UIImage(systemName: "play.fill"), for: .normal)
			avPlayer.pause()
		}
		
		isPlaying = !isPlaying
	}
	
	@IBAction func sliderDidChange(_ sender: Any) {
		let percentage = slider.value / slider.maximumValue
		let positionInSeconds = Double(slider.maximumValue * percentage)
		avPlayer.seek(to: CMTimeMakeWithSeconds(positionInSeconds, preferredTimescale: 1), toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
	}
	
	deinit {
		if let ob = periodicTimeObserver {
			avPlayer.removeObserver(self, forKeyPath: "currentItem.playbackLikelyToKeepUp")
			avPlayer.removeTimeObserver(ob)
		}
	}
}
