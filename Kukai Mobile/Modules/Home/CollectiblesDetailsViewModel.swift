//
//  CollectiblesDetailsViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/03/2022.
//

import Foundation
import KukaiCoreSwift

public class CollectiblesDetailsViewModel {
	
	public var name = ""
	public var description = ""
	
	private let mediaService = MediaProxyService()
	
	public func loadOfflineData(nft: NFT) {
		
		name = nft.name
		description = nft.description
	}
	
	public func getMediaType(nft: NFT, completion: @escaping ((Result<MediaProxyService.MediaType, ErrorResponse>) -> Void)) {
		mediaService.getMediaType(fromFormats: nft.metadata?.formats ?? [], orURL: nft.artifactURL, completion: completion)
	}
}

