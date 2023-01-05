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
	@IBOutlet weak var playPauseButton: UIButton!
	@IBOutlet weak var airPlayPlaceholderView: UIView!
	@IBOutlet weak var scrubber: UISlider!
	@IBOutlet weak var startTimeLabel: UILabel!
	@IBOutlet weak var endTimeLabel: UILabel!
	
	private var imageView: UIImageView? = nil
	private var avPlayer: AVPlayer? = nil
	private var isPlaying = false
	private var playbackLikelyToKeepUpContext = 0
	private var periodicTimeObserver: Any? = nil
	private var airPlayButton = AVRoutePickerView()
	private var didSetNowPlaying = false
	private var nowPlayingImage: UIImage? = nil
	private var nowPlayingTitle = ""
	private var nowPlayingArtist = ""
	private var nowPlayingAlbum = ""
	
	public var setup = false
	
	func setup(mediaContent: MediaContent, airPlayName: String, airPlayArtist: String, airPlayAlbum: String, avPlayer: AVPlayer) {
		self.setup = true
		self.avPlayer = avPlayer
		
		if let audioURL = mediaContent.mediaURL, let audioImageURL = mediaContent.mediaURL2 {
			imageView = UIImageView(frame: placeholderView.bounds)
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
			
			
			MediaProxyService.temporaryImageCache().retrieveImage(forKey: audioImageURL.absoluteString, options: []) { [weak self] result in
				guard let res = try? result.get() else {
					print("Didn't have image cached")
					return
				}
				
				print("Did have image cached")
				audioImageView.image = res.image
				
				
				let title = AVMutableMetadataItem()
				title.identifier = .commonIdentifierTitle
				title.value = (airPlayName as NSString)
				title.extendedLanguageTag = "und"
				
				let artist = AVMutableMetadataItem()
				artist.identifier = .commonIdentifierArtist
				artist.value = (airPlayArtist as NSString)
				artist.extendedLanguageTag = "und"
				
				let artwork = AVMutableMetadataItem()
				artwork.identifier = .commonIdentifierArtwork
				artwork.value = (res.image?.jpegData(compressionQuality: 1) ?? Data()) as NSData
				artwork.dataType = kCMMetadataBaseDataType_JPEG as String
				artwork.extendedLanguageTag = "und"
				
				avPlayer.currentItem?.externalMetadata = [title, artist, artwork]
				avPlayer.allowsExternalPlayback = false
				
				
				self?.nowPlayingTitle = airPlayName
				self?.nowPlayingArtist = airPlayArtist
				self?.nowPlayingAlbum = airPlayAlbum
				self?.nowPlayingImage = res.image ?? UIImage.unknownToken()
			}
			
			
		} else if let videoURL = mediaContent.mediaURL {
			
		}
		
		scrubber.value = 0
		setupScrubber()
		setupAirPlay()
	}
	
	private func setupScrubber() {
		guard let avPlayer = avPlayer else {
			return
		}
		
		avPlayer.addObserver(self, forKeyPath: "currentItem.playbackLikelyToKeepUp", options: .new, context: &playbackLikelyToKeepUpContext)
		periodicTimeObserver = avPlayer.addPeriodicTimeObserver(forInterval: .init(seconds: 1, preferredTimescale: 1), queue: nil) { [weak self] time in
			guard self?.scrubber.isTracking == false else { return }
			
			//if slider is not being touched, then update the slider from here
			self?.updateScrubber(with: time)
		}
	}
	
	private func setupAirPlay() {
		airPlayButton.frame = airPlayPlaceholderView.frame
		airPlayButton.tintColor = .white
		airPlayButton.translatesAutoresizingMaskIntoConstraints = false
		airPlayPlaceholderView.addSubview(airPlayButton)
		
		NSLayoutConstraint.activate([
			airPlayButton.leadingAnchor.constraint(equalTo: airPlayPlaceholderView.leadingAnchor),
			airPlayButton.trailingAnchor.constraint(equalTo: airPlayPlaceholderView.trailingAnchor),
			airPlayButton.topAnchor.constraint(equalTo: airPlayPlaceholderView.topAnchor),
			airPlayButton.bottomAnchor.constraint(equalTo: airPlayPlaceholderView.bottomAnchor)
		])
	}
	
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		guard let avPlayer = avPlayer else {
			return
		}
		
		if context == &playbackLikelyToKeepUpContext {
			if avPlayer.currentItem?.isPlaybackLikelyToKeepUp ?? false {
				//activityIndicator.stopAnimating()
				//activityIndicator.isHidden = true
				
				let duration = avPlayer.currentItem?.duration ?? CMTime()
				playPauseButton.isHidden = false
				scrubber.isHidden = false
				scrubber.minimumValue = 0
				scrubber.maximumValue = Float(CMTimeGetSeconds(duration))
				
				startTimeLabel.text = "0:00"
				endTimeLabel.text = duration.durationText
				
			} else {
				//activityIndicator.startAnimating()
				//activityIndicator.isHidden = false
			}
		}
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
		if !didSetNowPlaying {
			didSetNowPlaying = true
			return
		}
		
		let audioSession = AVAudioSession.sharedInstance()
		if let _ = try? audioSession.setCategory(.playback, mode: .default, policy: .longFormAudio) {
			
			MPNowPlayingInfoCenter.default().nowPlayingInfo = [
				MPMediaItemPropertyTitle: nowPlayingTitle,
				MPMediaItemPropertyArtist: nowPlayingArtist,
				MPMediaItemPropertyAlbumTitle: nowPlayingAlbum,
				MPNowPlayingInfoPropertyPlaybackRate: 1.0,
				MPMediaItemPropertyArtwork: MPMediaItemArtwork(boundsSize: nowPlayingImage?.size ?? CGSize(width: 50, height: 50)) { [weak self] size in
					return self?.nowPlayingImage?.resizedImage(Size: size) ?? UIImage.unknownToken()
				}
			]
			
			let commandCenter = MPRemoteCommandCenter.shared()
			
			commandCenter.stopCommand.addTarget { [weak self] commandEvent in
				print("Command: stopCommand")
				
				self?.commandPause()
				return .success
			}
			
			commandCenter.togglePlayPauseCommand.addTarget { [weak self] commandEvent in
				print("Command: togglePlayPauseCommand")
				
				if self?.isPlaying ?? true {
					self?.commandPause()
					
				} else {
					self?.commandPlay()
				}
				return .success
			}
			
			commandCenter.playCommand.addTarget { [weak self] commandEvent in
				print("Command: playCommand")
				
				self?.commandPlay()
				return .success
			}
			
			commandCenter.pauseCommand.addTarget { [weak self] commandEvent in
				print("Command: pauseCommand")
				
				self?.commandPause()
				return .success
			}
		}
	}
	
	private func commandPlay() {
		print("playing")
		
		playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
		avPlayer?.play()
		setNowPlaying()
		let _ = try? AVAudioSession.sharedInstance().setActive(true)
		
		if let player = avPlayer {
			MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = CMTimeGetSeconds(player.currentTime())
		}
		
		isPlaying = !isPlaying
	}
	
	private func commandPause() {
		print("pausing")
		
		playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
		avPlayer?.pause()
		let _ = try? AVAudioSession.sharedInstance().setActive(false)
		
		isPlaying = !isPlaying
	}
	
	@IBAction func scrubberDidChange(_ sender: Any) {
		let percentage = scrubber.value / scrubber.maximumValue
		let positionInSeconds = Double(scrubber.maximumValue * percentage)
		avPlayer?.seek(to: CMTimeMakeWithSeconds(positionInSeconds, preferredTimescale: 1), toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
	}
	
	deinit {
		if let ob = periodicTimeObserver {
			avPlayer?.removeObserver(self, forKeyPath: "currentItem.playbackLikelyToKeepUp")
			avPlayer?.removeTimeObserver(ob)
		}
	}
}
