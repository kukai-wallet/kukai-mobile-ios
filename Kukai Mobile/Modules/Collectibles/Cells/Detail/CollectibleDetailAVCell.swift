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
	@IBOutlet weak var mediaActivityView: UIActivityIndicatorView!
	@IBOutlet var aspectRatioConstraint: NSLayoutConstraint!
	
	private var isAudio = false
	private var isImageDownloaded = false
	private var isPlaybackReady = false
	private var isPlaying = false
	private var imageView: UIImageView? = nil
	private var playbackLikelyToKeepUpContext = 0
	private var playbackRateContext = 0
	private weak var playerController: CustomAVPlayerViewController? = nil
	
	private var airPlayName: String = ""
	private var airPlayArtist: String = ""
	private var airPlayAlbum: String = ""
	private var hasSetupNowPlaying = false
	private var commandCentreTargetStop: Any? = nil
	private var commandCentreTargetToggle: Any? = nil
	private var commandCentreTargetPlay: Any? = nil
	private var commandCentreTargetPause: Any? = nil
	
	public var setup = false
	public var timer: Timer? = nil
	
	func setup(mediaContent: MediaContent, airPlayName: String, airPlayArtist: String, airPlayAlbum: String, avplayerController: CustomAVPlayerViewController, layoutOnly: Bool) {
		if mediaContent.width > mediaContent.height {
			self.aspectRatioConstraint.isActive = false
			placeholderView.widthAnchor.constraint(equalTo: placeholderView.heightAnchor, multiplier: mediaContent.width/mediaContent.height).isActive = true
		}
		
		
		// Ignore everything else if only setting up the collectionview layout
		if layoutOnly { return }
		
		
		self.airPlayName = airPlayName
		self.airPlayArtist = airPlayArtist
		self.airPlayAlbum = airPlayAlbum
		
		mediaActivityView.startAnimating()
		self.playerController = avplayerController
		placeholderView.addSubview(avplayerController.view)
		avplayerController.view.frame = placeholderView.bounds
		avplayerController.view.backgroundColor = .clear
		avplayerController.player?.addObserver(self, forKeyPath: "currentItem.playbackLikelyToKeepUp", options: .new, context: &playbackLikelyToKeepUpContext)
		avplayerController.player?.addObserver(self, forKeyPath: "rate", options: .new, context: &playbackRateContext)
		avplayerController.updatesNowPlayingInfoCenter = false
		
		
		// if allowsExternalPlayback set to false, during airplay via the command centre, iOS correctly picks up that its a song and shows the album artwork + title + album
		// With this setup, videos however do not cast to the external device
		// if allowsExternalPlayback set to true, audio will play and it will show the title, but no album artwork
		// it seems as though this feature was only meant for videos. For now, its disabled for audio and enabled for video
		
		
		// Audio + image only work
		if let audioImageURL = mediaContent.mediaURL2 {
			isAudio = true
			avplayerController.player?.allowsExternalPlayback = false
			
			imageView = UIImageView(frame: placeholderView.bounds)
			imageView?.contentMode = .scaleAspectFit
			guard let audioImageView = imageView else {
				return
			}
			
			guard let contentView = avplayerController.contentOverlayView else { return }
			
			contentView.addSubview(audioImageView)
			audioImageView.translatesAutoresizingMaskIntoConstraints = false
			NSLayoutConstraint.activate([
				audioImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
				audioImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
				audioImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
				audioImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
			])
			
			MediaProxyService.imageCache(forType: .temporary).retrieveImage(forKey: audioImageURL.absoluteString, options: []) { [weak self] result in
				guard let res = try? result.get() else {
					return
				}
				
				audioImageView.image = res.image
				self?.isImageDownloaded = true
				self?.checkAudioImageStatus()
			}
		}
		// Video only work
		else {
			isAudio = false
			avplayerController.player?.allowsExternalPlayback = true
			avplayerController.player?.isMuted = true
		}
		
		setup = true
	}
	
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		if context == &playbackLikelyToKeepUpContext {
			if self.playerController?.player?.currentItem?.isPlaybackLikelyToKeepUp == true {
				isPlaybackReady = true
				
				if !isAudio {
					mediaActivityView.stopAnimating()
					mediaActivityView.isHidden = true
					self.playerController?.player?.play()
					
					
				} else {
					checkAudioImageStatus()
				}
			}
		} else if context == &playbackRateContext, let playRate = playerController?.player?.rate {
			if playRate == 0.0 {
				updateNowPlaying(isPause: true)
				
			} else if hasSetupNowPlaying {
				updateNowPlaying(isPause: false)
				
			} else {
				setupNowPlaying()
			}
		}
	}
	
	deinit {
		playerController?.player?.removeObserver(self, forKeyPath: "currentItem.playbackLikelyToKeepUp", context: &playbackLikelyToKeepUpContext)
		playerController?.player?.removeObserver(self, forKeyPath: "rate", context: &playbackRateContext)
		
		clearCommandCenterCommands()
	}
	
	private func setupNowPlaying() {
		let elapsedTime = CMTimeGetSeconds(playerController?.player?.currentTime() ?? CMTime(value: 0, timescale: CMTimeScale()))
		let duration = CMTimeGetSeconds(playerController?.player?.currentItem?.duration ?? CMTime(value: 0, timescale: CMTimeScale()))
		
		MPNowPlayingInfoCenter.default().nowPlayingInfo = [
			MPMediaItemPropertyAlbumTitle: airPlayAlbum,
			MPNowPlayingInfoPropertyPlaybackRate: 1.0,
			MPMediaItemPropertyTitle: airPlayName,
			MPMediaItemPropertyArtist: airPlayArtist,
			MPNowPlayingInfoPropertyElapsedPlaybackTime: elapsedTime,
			MPMediaItemPropertyPlaybackDuration: duration,
			MPNowPlayingInfoPropertyMediaType: isAudio ? 1 : 2
		]
		
		if let image = imageView?.image {
			MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { size in
				return image.resizedImage(size: size) ?? UIImage.unknownToken()
			}
		}
		
		setupCommands()
		hasSetupNowPlaying = true
	}
	
	func updateNowPlaying(isPause: Bool) {
		let elapsedTime = CMTimeGetSeconds(playerController?.player?.currentTime() ?? CMTime(value: 0, timescale: CMTimeScale()))
		
		var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo
		nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsedTime
		nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = isPause ? 0 : 1
		MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
	}
	
	private func checkAudioImageStatus() {
		if isImageDownloaded && isPlaybackReady {
			mediaActivityView.stopAnimating()
			mediaActivityView.isHidden = true
		}
	}
	
	private func setupCommands() {
		if let _ = try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, policy: isAudio ? .longFormAudio : .longFormVideo) {
			let commandCenter = MPRemoteCommandCenter.shared()
			
			commandCenter.stopCommand.isEnabled = true
			commandCentreTargetStop = commandCenter.stopCommand.addTarget { [weak self] commandEvent in
				self?.commandPause()
				return .success
			}
			
			commandCenter.togglePlayPauseCommand.isEnabled = true
			commandCentreTargetToggle = commandCenter.togglePlayPauseCommand.addTarget { [weak self] commandEvent in
				if self?.isPlaying ?? true {
					self?.commandPause()
					
				} else {
					self?.commandPlay()
				}
				return .success
			}
			
			commandCenter.playCommand.isEnabled = true
			commandCentreTargetPlay = commandCenter.playCommand.addTarget { [weak self] commandEvent in
				self?.commandPlay()
				return .success
			}
			
			commandCenter.pauseCommand.isEnabled = true
			commandCentreTargetPause = commandCenter.pauseCommand.addTarget { [weak self] commandEvent in
				self?.commandPause()
				return .success
			}
		}
	}
	
	private func clearCommandCenterCommands() {
		let commandCenter = MPRemoteCommandCenter.shared()
		
		commandCenter.stopCommand.isEnabled = false
		commandCenter.togglePlayPauseCommand.isEnabled = false
		commandCenter.playCommand.isEnabled = false
		commandCenter.pauseCommand.isEnabled = false
		
		commandCenter.stopCommand.removeTarget(commandCentreTargetStop)
		commandCenter.togglePlayPauseCommand.removeTarget(commandCentreTargetToggle)
		commandCenter.playCommand.removeTarget(commandCentreTargetPlay)
		commandCenter.pauseCommand.removeTarget(commandCentreTargetPause)
	}
	
	private func commandPlay() {
		playerController?.player?.play()
		let _ = try? AVAudioSession.sharedInstance().setActive(true)
		
		isPlaying = !isPlaying
	}
	
	private func commandPause() {
		isPlaying = !isPlaying
		
		playerController?.player?.pause()
		let _ = try? AVAudioSession.sharedInstance().setActive(false)
	}
}
