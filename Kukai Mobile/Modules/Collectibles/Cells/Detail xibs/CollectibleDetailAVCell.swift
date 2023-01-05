//
//  CollectibleDetailAVCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 04/01/2023.
//

import UIKit
import AVKit
import KukaiCoreSwift

class CollectibleDetailAVCell: UICollectionViewCell {

	@IBOutlet weak var placeholderView: UIView!
	@IBOutlet weak var playPauseButton: UIButton!
	@IBOutlet weak var airPlayPlaceholderView: UIView!
	@IBOutlet weak var scrubber: UISlider!
	@IBOutlet weak var startTimeLabel: UILabel!
	@IBOutlet weak var endTimeLabel: UILabel!
	
	private var imageView: UIImageView? = nil
	
	public var setup = false
	
	func setup(mediaContent: MediaContent, airPlayName: String, airPlayArtist: String, avPlayer: AVPlayer) {
		setup = true
		
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
			
			
			MediaProxyService.temporaryImageCache().retrieveImage(forKey: audioImageURL.absoluteString, options: []) { result in
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
				
				
				/*
				let audioSession = AVAudioSession.sharedInstance()
				if let sessionResult = try? audioSession.setCategory(.playback, mode: .default, policy: .longFormAudio) {
					print("details set on shared instance: \(sessionResult)")
					
					UIApplication.shared.beginReceivingRemoteControlEvents()
					let commandCenter = MPRemoteCommandCenter.shared()
					
					commandCenter.playCommand.isEnabled = true
					commandCenter.pauseCommand.isEnabled = true
					
					commandCenter.playCommand.addTarget { [self] (commandEvent) -> MPRemoteCommandHandlerStatus in
						print("inside remote player play command")
						player.play()
						return MPRemoteCommandHandlerStatus.success
					}
					
					commandCenter.pauseCommand.addTarget { [self] (commandEvent) -> MPRemoteCommandHandlerStatus in
						print("inside remote player pause command")
						player.pause()
						return MPRemoteCommandHandlerStatus.success
					}
				}
				*/
			}
			
			
		} else if let videoURL = mediaContent.mediaURL {
			
		}
	}
	
	/*
	private func setupScrubber() {
		avPlayer.addObserver(self, forKeyPath: "currentItem.playbackLikelyToKeepUp", options: .new, context: &playbackLikelyToKeepUpContext)
		periodicTimeObserver = avPlayer.addPeriodicTimeObserver(forInterval: .init(seconds: 1, preferredTimescale: 1), queue: nil) { [weak self] time in
			guard self?.slider.isTracking == false else { return }
			
			//if slider is not being touched, then update the slider from here
			self?.updateSlider(with: time)
		}
	}
	*/
}




/*
// Make sure we only register the player controller once
if self.playerController == nil, let url = obj.mediaURL {
	
	self.playerController = AVPlayerViewController()
	
	
	/*
	 MediaProxyService.cacheImage(url: obj.mediaURL2, cache: MediaProxyService.temporaryImageCache()) { size in
	 print("cached")
	 }
	 */
	
	MediaProxyService.temporaryImageCache().retrieveImage(forKey: obj.mediaURL2?.absoluteString ?? "", options: []) { result in
		guard let res = try? result.get() else {
			print("Didn't have image cached")
			return
		}
		
		print("Did have image cached")
		
		self.playerControllerBackground.image = res.image
		self.playerController?.contentOverlayView?.addSubview(self.playerControllerBackground)
		
		if let overlay = self.playerController?.contentOverlayView {
			self.playerControllerBackground.translatesAutoresizingMaskIntoConstraints = false
			NSLayoutConstraint.activate([
				self.playerControllerBackground.leadingAnchor.constraint(equalTo: overlay.leadingAnchor),
				self.playerControllerBackground.trailingAnchor.constraint(equalTo: overlay.trailingAnchor),
				self.playerControllerBackground.topAnchor.constraint(equalTo: overlay.topAnchor),
				self.playerControllerBackground.bottomAnchor.constraint(equalTo: overlay.bottomAnchor)
			])
		}
		
		let playerItem = AVPlayerItem(url: url)
		
		let title = AVMutableMetadataItem()
		title.identifier = .commonIdentifierTitle
		title.value = (self.nft?.name ?? "123") as NSString
		title.extendedLanguageTag = "und"
		
		let artist = AVMutableMetadataItem()
		artist.identifier = .commonIdentifierArtist
		artist.value = (self.nft?.parentAlias ?? "456") as NSString
		artist.extendedLanguageTag = "und"
		
		let artwork = AVMutableMetadataItem()
		artwork.identifier = .commonIdentifierArtwork
		artwork.value = (self.playerControllerBackground.image?.jpegData(compressionQuality: 1) ?? Data()) as NSData
		artwork.dataType = kCMMetadataBaseDataType_JPEG as String
		artwork.extendedLanguageTag = "und"
		
		playerItem.externalMetadata = [title, artist, artwork]
		
		//self.playerController?.updatesNowPlayingInfoCenter = false
		
		
		let player = AVQueuePlayer(playerItem: playerItem)
		
		
		/*
		 let artwork2 = MPMediaItemArtwork(boundsSize: CGSize(width: 300, height: 300)) { size in
		 print("Inside MPMediaItemArtwork request")
		 return res.image ?? UIImage.unknownToken()
		 }
		 
		 let mpNowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
		 mpNowPlayingInfoCenter.nowPlayingInfo = [
		 MPMediaItemPropertyTitle: "Video Name",
		 MPMediaItemPropertyArtist: "Artist Name",
		 MPMediaItemPropertyAlbumTitle: "Album Title",
		 MPMediaItemPropertyArtwork: artwork2,
		 MPMediaItemPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue, // can also be audio
		 MPNowPlayingInfoPropertyElapsedPlaybackTime: 0.0, // just starting
		 MPNowPlayingInfoPropertyPlaybackRate: 1.0, // this indicates the playing speed
		 ]
		 */
		
		player.allowsExternalPlayback = false
		
		
		let audioSession = AVAudioSession.sharedInstance()
		if let sessionResult = try? audioSession.setCategory(.playback, mode: .default, policy: .longFormAudio) {
			print("details set on shared instance: \(sessionResult)")
			
			UIApplication.shared.beginReceivingRemoteControlEvents()
			let commandCenter = MPRemoteCommandCenter.shared()
			
			commandCenter.playCommand.isEnabled = true
			commandCenter.pauseCommand.isEnabled = true
			
			commandCenter.playCommand.addTarget { [self] (commandEvent) -> MPRemoteCommandHandlerStatus in
				print("inside remote player play command")
				player.play()
				return MPRemoteCommandHandlerStatus.success
			}
			
			commandCenter.pauseCommand.addTarget { [self] (commandEvent) -> MPRemoteCommandHandlerStatus in
				print("inside remote player pause command")
				player.pause()
				return MPRemoteCommandHandlerStatus.success
			}
			
		}
		
		
		
		
		/*
		 let audioSession = AVAudioSession.sharedInstance()
		 if let sessionResult = try? audioSession.setCategory(.playback, mode: .default, policy: .longFormAudio) {
		 print("details set on shared instance: \(sessionResult)")
		 
		 let artwork = MPMediaItemArtwork(boundsSize: CGSize(width: 300, height: 300)) { size in
		 print("Inside MPMediaItemArtwork request")
		 return res.image ?? UIImage.unknownToken()
		 }
		 
		 //self.playerController?.updatesNowPlayingInfoCenter = true
		 //self.playerController?.player?.currentItem?.nowPlayingInfo = [MPMediaItemPropertyTitle: self.nft?.name ?? "123", MPMediaItemPropertyArtist: self.nft?.parentAlias ?? "456", MPMediaItemPropertyArtwork: artwork]
		 
		 //MPNowPlayingInfoCenter.default().nowPlayingInfo = [MPMediaItemPropertyTitle: self.nft?.name ?? "123", MPMediaItemPropertyArtist: self.nft?.parentAlias ?? "456", MPMediaItemPropertyArtwork: artwork]
		 } else {
		 print("unable to set shared session details")
		 }
		 */
		
		self.playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
		self.playerController?.player = player
		self.playerController?.player?.play()
		
	}
}

if let pvc = self.playerController {
	parsedCell.setup(avplayerController: pvc)
}
*/










