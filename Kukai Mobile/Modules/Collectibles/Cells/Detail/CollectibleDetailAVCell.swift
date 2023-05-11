//
//  CollectibleDetailAVCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 04/01/2023.
//

import UIKit
import AVKit
import KukaiCoreSwift
import MediaPlayer

class CollectibleDetailAVCell: UICollectionViewCell {

	@IBOutlet weak var placeholderView: UIView!
	@IBOutlet weak var quantityView: UIView!
	@IBOutlet weak var quantityLabel: UILabel!
	@IBOutlet weak var playPauseButton: UIButton!
	@IBOutlet weak var airPlayPlaceholderView: UIView!
	@IBOutlet weak var scrubber: UISlider!
	@IBOutlet weak var startTimeLabel: UILabel!
	@IBOutlet weak var endTimeLabel: UILabel!
	@IBOutlet weak var mediaActivityView: UIActivityIndicatorView!
	@IBOutlet weak var scrubberActivityView: UIActivityIndicatorView!
	
	private var imageView: UIImageView? = nil
	private var avPlayer: AVPlayer? = nil
	private var avPlayerLayer: AVPlayerLayer? = nil
	private var airPlayTextLayer: CATextLayer? = nil
	private var isPlaying = false
	private var periodicTimeObserver: Any? = nil
	private var playbackReadyObservation: NSKeyValueObservation? = nil
	private var rateChangeObservation: NSKeyValueObservation? = nil
	private var airPlayButton = AVRoutePickerView()
	private var didSetNowPlaying = false
	private var isAudio = false
	private var nowPlayingInfo: [String: Any] = [:] {
		didSet {
			MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
		}
	}
	
	public var setup = false
	
	func setup(mediaContent: MediaContent, airPlayName: String, airPlayArtist: String, airPlayAlbum: String, player: AVPlayer, playerLayer: AVPlayerLayer?, layoutOnly: Bool) {
		self.setup = true
		self.avPlayer = player
		self.showScrubberLoading()
		
		// Load image if not only perfroming collectionview layout logic
		if layoutOnly {
			return
		}
		
		// Quantity
		if let quantity = mediaContent.quantity {
			quantityView.isHidden = false
			quantityLabel.text = quantity
			quantityView.layer.zPosition = 100
			
		} else {
			quantityView.isHidden = true
		}
		
		
		// Audio + image
		if let audioImageURL = mediaContent.mediaURL2 {
			isAudio = true
			if mediaContent.isThumbnail {
				mediaActivityView.startAnimating()
			} else {
				mediaActivityView.isHidden = true
			}
			
			imageView = UIImageView(frame: placeholderView.bounds)
			imageView?.contentMode = .scaleAspectFit
			guard let audioImageView = imageView else {
				return
			}
			
			placeholderView.addSubview(audioImageView)
			audioImageView.translatesAutoresizingMaskIntoConstraints = false
			NSLayoutConstraint.activate([
				audioImageView.leadingAnchor.constraint(equalTo: placeholderView.leadingAnchor),
				audioImageView.trailingAnchor.constraint(equalTo: placeholderView.trailingAnchor),
				audioImageView.topAnchor.constraint(equalTo: placeholderView.topAnchor),
				audioImageView.bottomAnchor.constraint(equalTo: placeholderView.bottomAnchor)
			])
			
			
			MediaProxyService.imageCache().retrieveImage(forKey: audioImageURL.absoluteString, options: []) { [weak self] result in
				guard let res = try? result.get() else {
					return
				}
				
				audioImageView.image = res.image
				player.allowsExternalPlayback = false
				
				self?.nowPlayingInfo = [
					MPMediaItemPropertyTitle: airPlayName,
					MPMediaItemPropertyArtist: airPlayArtist,
					MPMediaItemPropertyAlbumTitle: airPlayAlbum,
					MPNowPlayingInfoPropertyPlaybackRate: 1.0,
					MPMediaItemPropertyArtwork: MPMediaItemArtwork(boundsSize: res.image?.size ?? CGSize(width: 50, height: 50)) { size in
						return res.image?.resizedImage(size: size) ?? UIImage.unknownToken()
					}
				]
			}
			
			
		} else if let pLayer = playerLayer {
			isAudio = false
			mediaActivityView.startAnimating()
			
			let attributedString = NSAttributedString(string: "Playing on external device", attributes: [
				NSAttributedString.Key.foregroundColor: UIColor.colorNamed("Txt2"),
				NSAttributedString.Key.font: UIFont.custom(ofType: .bold, andSize: 14)
			])
			airPlayTextLayer = CATextLayer()
			airPlayTextLayer?.string = attributedString
			airPlayTextLayer?.contentsScale = UIScreen.main.scale
			airPlayTextLayer?.frame = CGRect(x: 0, y: placeholderView.frame.height/2 - 10, width: placeholderView.frame.width, height: 20)
			airPlayTextLayer?.alignmentMode = .center
			airPlayTextLayer?.isHidden = true
			
			pLayer.frame = placeholderView.bounds
			
			placeholderView.layer.addSublayer(airPlayTextLayer ?? CATextLayer())
			placeholderView.layer.addSublayer(pLayer)
			self.avPlayerLayer = pLayer
			
			self.nowPlayingInfo = [
				MPMediaItemPropertyTitle: airPlayName,
				MPMediaItemPropertyArtist: airPlayArtist,
				MPMediaItemPropertyAlbumTitle: airPlayAlbum,
				MPNowPlayingInfoPropertyPlaybackRate: 1.0
			]
		}
		
		scrubber.value = 0
		setupScrubber()
		setupAirPlay()
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		if let layer = avPlayerLayer {
			layer.frame = placeholderView.bounds
			airPlayTextLayer?.frame = CGRect(x: 0, y: placeholderView.frame.height/2 - 10, width: placeholderView.frame.width, height: 20)
		}
	}
	
	private func setupScrubber() {
		guard let avPlayer = avPlayer else {
			return
		}
		
		playbackReadyObservation = avPlayer.currentItem?.observe(\.status, changeHandler: { [weak self] item, value in
			if item.status == .readyToPlay {
				self?.hideScrubberLoading()
				
				let duration = avPlayer.currentItem?.duration ?? CMTime()
				self?.scrubber.minimumValue = 0
				self?.scrubber.maximumValue = Float(CMTimeGetSeconds(duration))
				
				self?.nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = CMTimeGetSeconds(duration)
				
				self?.startTimeLabel.text = avPlayer.currentItem?.currentTime().durationText
				self?.endTimeLabel.text = duration.durationText
				
				if self?.isAudio == false {
					// If video, make sure we stop the spinner when the video is ready
					self?.mediaActivityView.stopAnimating()
					self?.mediaActivityView.isHidden = true
					self?.airPlayTextLayer?.isHidden = false
				}
			}
		})
		
		rateChangeObservation = avPlayer.observe(\.rate) { [weak self] avPlayer, value in
			if avPlayer.rate == 0 && self?.isPlaying == true {
				self?.commandReset()
			}
		}
		
		periodicTimeObserver = avPlayer.addPeriodicTimeObserver(forInterval: .init(seconds: 1, preferredTimescale: 1), queue: nil) { [weak self] time in
			guard self?.scrubber.isTracking == false else { return }
			
			//if slider is not being touched, then update the slider from here
			self?.updateScrubber(with: time)
		}
	}
	
	private func showScrubberLoading() {
		scrubberActivityView.isHidden = false
		scrubberActivityView.startAnimating()
		
		playPauseButton.isHidden = true
		scrubber.isHidden = true
		airPlayPlaceholderView.isHidden = true
		startTimeLabel.isHidden = true
		endTimeLabel.isHidden = true
	}
	
	private func hideScrubberLoading() {
		scrubberActivityView.stopAnimating()
		scrubberActivityView.isHidden = true
		
		playPauseButton.isHidden = false
		scrubber.isHidden = false
		airPlayPlaceholderView.isHidden = false
		startTimeLabel.isHidden = false
		endTimeLabel.isHidden = false
	}
	
	private func setupAirPlay() {
		airPlayButton.frame = airPlayPlaceholderView.frame
		airPlayButton.tintColor = .colorNamed("playerIconSlider")
		airPlayButton.activeTintColor = .colorNamed("playerIconSlider")
		airPlayButton.translatesAutoresizingMaskIntoConstraints = false
		airPlayPlaceholderView.addSubview(airPlayButton)
		
		NSLayoutConstraint.activate([
			airPlayButton.leadingAnchor.constraint(equalTo: airPlayPlaceholderView.leadingAnchor),
			airPlayButton.trailingAnchor.constraint(equalTo: airPlayPlaceholderView.trailingAnchor),
			airPlayButton.topAnchor.constraint(equalTo: airPlayPlaceholderView.topAnchor),
			airPlayButton.bottomAnchor.constraint(equalTo: airPlayPlaceholderView.bottomAnchor)
		])
	}
	
	private func updateScrubber(with: CMTime) {
		let currentTime = avPlayer?.currentItem?.currentTime() ?? CMTime()
		scrubber.value = Float(CMTimeGetSeconds(currentTime))
		startTimeLabel.text = currentTime.durationText
	}
	
	@IBAction func playPauseButtonTapped(_ sender: Any) {
		if !isPlaying {
			commandPlay()
			
		} else {
			commandPause()
		}
	}
	
	private func setNowPlaying() {
		if didSetNowPlaying {
			return
		}
		didSetNowPlaying = true
		
		if let _ = try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, policy: isAudio ? .longFormAudio : .longFormVideo) {
			let commandCenter = MPRemoteCommandCenter.shared()
			commandCenter.stopCommand.addTarget { [weak self] commandEvent in
				self?.commandPause()
				return .success
			}
			
			commandCenter.togglePlayPauseCommand.addTarget { [weak self] commandEvent in
				if self?.isPlaying ?? true {
					self?.commandPause()
					
				} else {
					self?.commandPlay()
				}
				return .success
			}
			
			commandCenter.playCommand.addTarget { [weak self] commandEvent in
				self?.commandPlay()
				return .success
			}
			
			commandCenter.pauseCommand.addTarget { [weak self] commandEvent in
				self?.commandPause()
				return .success
			}
		}
	}
	
	private func commandPlay() {
		playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
		avPlayer?.play()
		setNowPlaying()
		let _ = try? AVAudioSession.sharedInstance().setActive(true)
		
		if let player = avPlayer {
			self.nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = CMTimeGetSeconds(player.currentTime())
		}
		
		isPlaying = !isPlaying
	}
	
	private func commandPause() {
		playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
		avPlayer?.pause()
		let _ = try? AVAudioSession.sharedInstance().setActive(false)
		
		isPlaying = !isPlaying
	}
	
	private func commandReset() {
		playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
		avPlayer?.seek(to: CMTime.zero)
		
		isPlaying = !isPlaying
	}
	
	@IBAction func scrubberDidChange(_ sender: Any) {
		let percentage = scrubber.value / scrubber.maximumValue
		let positionInSeconds = Double(scrubber.maximumValue * percentage)
		avPlayer?.seek(to: CMTimeMakeWithSeconds(positionInSeconds, preferredTimescale: 1), toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
	}
	
	deinit {
		if let ob = periodicTimeObserver {
			playbackReadyObservation = nil
			rateChangeObservation = nil
			avPlayer?.removeTimeObserver(ob)
			
			let commandCenter = MPRemoteCommandCenter.shared()
			commandCenter.togglePlayPauseCommand.removeTarget(self)
			commandCenter.stopCommand.removeTarget(self)
			commandCenter.playCommand.removeTarget(self)
			commandCenter.pauseCommand.removeTarget(self)
			
			didSetNowPlaying = false
		}
	}
}
