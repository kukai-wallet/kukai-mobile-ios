//
//  TokenStateServiceTests.swift
//  Kukai MobileTests
//
//  Created by Simon Mcloughlin on 02/10/2024.
//

import XCTest
@testable import Kukai_Mobile
@testable import KukaiCoreSwift

class TokenStateServiceTests: XCTestCase {

	override func setUpWithError() throws {
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}

	override func tearDownWithError() throws {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
	}
	
	func testMove() {
		let address = "tz1abc123"
		let token1 = Token(name: "Token1", symbol: "Token1", tokenType: .fungible, faVersion: .fa1_2, balance: TokenAmount.zero(), thumbnailURL: nil, tokenContractAddress: "KT1abc11111", tokenId: nil, nfts: nil, mintingTool: nil)
		let token2 = Token(name: "Token2", symbol: "Token2", tokenType: .fungible, faVersion: .fa1_2, balance: TokenAmount.zero(), thumbnailURL: nil, tokenContractAddress: "KT1abc22222", tokenId: nil, nfts: nil, mintingTool: nil)
		let token3 = Token(name: "Token3", symbol: "Token3", tokenType: .fungible, faVersion: .fa1_2, balance: TokenAmount.zero(), thumbnailURL: nil, tokenContractAddress: "KT1abc33333", tokenId: nil, nfts: nil, mintingTool: nil)
		let token4 = Token(name: "Token4", symbol: "Token4", tokenType: .fungible, faVersion: .fa1_2, balance: TokenAmount.zero(), thumbnailURL: nil, tokenContractAddress: "KT1abc44444", tokenId: nil, nfts: nil, mintingTool: nil)
		let token5 = Token(name: "Token5", symbol: "Token5", tokenType: .fungible, faVersion: .fa1_2, balance: TokenAmount.zero(), thumbnailURL: nil, tokenContractAddress: "KT1abc55555", tokenId: nil, nfts: nil, mintingTool: nil)
		
		
		
		// Test basic setup
		let _ = TokenStateService.shared.addFavourite(forAddress: address, token: token1)
		let _ = TokenStateService.shared.addFavourite(forAddress: address, token: token2)
		let _ = TokenStateService.shared.addFavourite(forAddress: address, token: token3)
		let _ = TokenStateService.shared.addFavourite(forAddress: address, token: token4)
		let _ = TokenStateService.shared.addFavourite(forAddress: address, token: token5)
		
		let index1 = TokenStateService.shared.isFavourite(forAddress: address, token: token1) ?? -1
		let index2 = TokenStateService.shared.isFavourite(forAddress: address, token: token2) ?? -1
		let index3 = TokenStateService.shared.isFavourite(forAddress: address, token: token3) ?? -1
		let index4 = TokenStateService.shared.isFavourite(forAddress: address, token: token4) ?? -1
		let index5 = TokenStateService.shared.isFavourite(forAddress: address, token: token5) ?? -1
		
		XCTAssert(index1 == 1, index1.description)
		XCTAssert(index2 == 2, index2.description)
		XCTAssert(index3 == 3, index3.description)
		XCTAssert(index4 == 4, index4.description)
		XCTAssert(index5 == 5, index5.description)
		
		
		
		// Test move bottom to top
		let _ = TokenStateService.shared.moveFavouriteBalance(forAddress: address, forToken: token5, toIndex: 1)
		
		let moveIndex0_1 = TokenStateService.shared.isFavourite(forAddress: address, token: token1) ?? -1
		let moveIndex0_2 = TokenStateService.shared.isFavourite(forAddress: address, token: token2) ?? -1
		let moveIndex0_3 = TokenStateService.shared.isFavourite(forAddress: address, token: token3) ?? -1
		let moveIndex0_4 = TokenStateService.shared.isFavourite(forAddress: address, token: token4) ?? -1
		let moveIndex0_5 = TokenStateService.shared.isFavourite(forAddress: address, token: token5) ?? -1
		
		XCTAssert(moveIndex0_1 == 2, moveIndex0_1.description)
		XCTAssert(moveIndex0_2 == 3, moveIndex0_2.description)
		XCTAssert(moveIndex0_3 == 4, moveIndex0_3.description)
		XCTAssert(moveIndex0_4 == 5, moveIndex0_4.description)
		XCTAssert(moveIndex0_5 == 1, moveIndex0_5.description)
		
		
		
		// Test move bottom to top again
		let _ = TokenStateService.shared.moveFavouriteBalance(forAddress: address, forToken: token4, toIndex: 1)
		
		let moveIndex1_1 = TokenStateService.shared.isFavourite(forAddress: address, token: token1) ?? -1
		let moveIndex1_2 = TokenStateService.shared.isFavourite(forAddress: address, token: token2) ?? -1
		let moveIndex1_3 = TokenStateService.shared.isFavourite(forAddress: address, token: token3) ?? -1
		let moveIndex1_4 = TokenStateService.shared.isFavourite(forAddress: address, token: token4) ?? -1
		let moveIndex1_5 = TokenStateService.shared.isFavourite(forAddress: address, token: token5) ?? -1
		
		XCTAssert(moveIndex1_1 == 3, moveIndex1_1.description)
		XCTAssert(moveIndex1_2 == 4, moveIndex1_2.description)
		XCTAssert(moveIndex1_3 == 5, moveIndex1_3.description)
		XCTAssert(moveIndex1_4 == 1, moveIndex1_4.description)
		XCTAssert(moveIndex1_5 == 2, moveIndex1_5.description)
		
		
		
		// Test move bottom to bottom
		let _ = TokenStateService.shared.moveFavouriteBalance(forAddress: address, forToken: token4, toIndex: 6)
		
		let moveIndex2_1 = TokenStateService.shared.isFavourite(forAddress: address, token: token1) ?? -1
		let moveIndex2_2 = TokenStateService.shared.isFavourite(forAddress: address, token: token2) ?? -1
		let moveIndex2_3 = TokenStateService.shared.isFavourite(forAddress: address, token: token3) ?? -1
		let moveIndex2_4 = TokenStateService.shared.isFavourite(forAddress: address, token: token4) ?? -1
		let moveIndex2_5 = TokenStateService.shared.isFavourite(forAddress: address, token: token5) ?? -1
		
		XCTAssert(moveIndex2_1 == 2, moveIndex2_1.description)
		XCTAssert(moveIndex2_2 == 3, moveIndex2_2.description)
		XCTAssert(moveIndex2_3 == 4, moveIndex2_3.description)
		XCTAssert(moveIndex2_4 == 5, moveIndex2_4.description)
		XCTAssert(moveIndex2_5 == 1, moveIndex2_5.description)
		
		
		
		// Test move bottom to bottom again
		let _ = TokenStateService.shared.moveFavouriteBalance(forAddress: address, forToken: token5, toIndex: 6)
		
		let moveIndex3_1 = TokenStateService.shared.isFavourite(forAddress: address, token: token1) ?? -1
		let moveIndex3_2 = TokenStateService.shared.isFavourite(forAddress: address, token: token2) ?? -1
		let moveIndex3_3 = TokenStateService.shared.isFavourite(forAddress: address, token: token3) ?? -1
		let moveIndex3_4 = TokenStateService.shared.isFavourite(forAddress: address, token: token4) ?? -1
		let moveIndex3_5 = TokenStateService.shared.isFavourite(forAddress: address, token: token5) ?? -1
		
		XCTAssert(moveIndex3_1 == 1, moveIndex3_1.description)
		XCTAssert(moveIndex3_2 == 2, moveIndex3_2.description)
		XCTAssert(moveIndex3_3 == 3, moveIndex3_3.description)
		XCTAssert(moveIndex3_4 == 4, moveIndex3_4.description)
		XCTAssert(moveIndex3_5 == 5, moveIndex3_5.description)
		
		
		
		// Clean up before another test
		TokenStateService.shared.deleteAllCaches()
	}
	
	func testMoveSmall() {
		let address = "tz1abc123"
		let token1 = Token(name: "Token1", symbol: "Token1", tokenType: .fungible, faVersion: .fa1_2, balance: TokenAmount.zero(), thumbnailURL: nil, tokenContractAddress: "KT1abc11111", tokenId: nil, nfts: nil, mintingTool: nil)
		let token2 = Token(name: "Token2", symbol: "Token2", tokenType: .fungible, faVersion: .fa1_2, balance: TokenAmount.zero(), thumbnailURL: nil, tokenContractAddress: "KT1abc22222", tokenId: nil, nfts: nil, mintingTool: nil)
		
		
		
		// Test basic setup
		let _ = TokenStateService.shared.addFavourite(forAddress: address, token: token1)
		let _ = TokenStateService.shared.addFavourite(forAddress: address, token: token2)
		
		let index1 = TokenStateService.shared.isFavourite(forAddress: address, token: token1) ?? -1
		let index2 = TokenStateService.shared.isFavourite(forAddress: address, token: token2) ?? -1
		
		XCTAssert(index1 == 1, index1.description)
		XCTAssert(index2 == 2, index2.description)
		
		
		
		// Test move bottom to top
		let _ = TokenStateService.shared.moveFavouriteBalance(forAddress: address, forToken: token2, toIndex: 1)
		
		let moveIndex0_1 = TokenStateService.shared.isFavourite(forAddress: address, token: token1) ?? -1
		let moveIndex0_2 = TokenStateService.shared.isFavourite(forAddress: address, token: token2) ?? -1
		
		XCTAssert(moveIndex0_1 == 2, moveIndex0_1.description)
		XCTAssert(moveIndex0_2 == 1, moveIndex0_2.description)
		
		
		
		// Test move bottom to top again
		let _ = TokenStateService.shared.moveFavouriteBalance(forAddress: address, forToken: token1, toIndex: 1)
		
		let moveIndex1_1 = TokenStateService.shared.isFavourite(forAddress: address, token: token1) ?? -1
		let moveIndex1_2 = TokenStateService.shared.isFavourite(forAddress: address, token: token2) ?? -1
		
		XCTAssert(moveIndex1_1 == 1, moveIndex1_1.description)
		XCTAssert(moveIndex1_2 == 2, moveIndex1_2.description)
		
		
		
		// Test move bottom to bottom
		let _ = TokenStateService.shared.moveFavouriteBalance(forAddress: address, forToken: token1, toIndex: 3)
		
		let moveIndex2_1 = TokenStateService.shared.isFavourite(forAddress: address, token: token1) ?? -1
		let moveIndex2_2 = TokenStateService.shared.isFavourite(forAddress: address, token: token2) ?? -1
		
		XCTAssert(moveIndex2_1 == 2, moveIndex2_1.description)
		XCTAssert(moveIndex2_2 == 1, moveIndex2_2.description)
		
		
		
		// Test move bottom to bottom again
		let _ = TokenStateService.shared.moveFavouriteBalance(forAddress: address, forToken: token2, toIndex: 3)
		
		let moveIndex3_1 = TokenStateService.shared.isFavourite(forAddress: address, token: token1) ?? -1
		let moveIndex3_2 = TokenStateService.shared.isFavourite(forAddress: address, token: token2) ?? -1
		
		XCTAssert(moveIndex3_1 == 1, moveIndex3_1.description)
		XCTAssert(moveIndex3_2 == 2, moveIndex3_2.description)
		
		
		
		// Clean up before another test
		TokenStateService.shared.deleteAllCaches()
	}
	
	func testMoveOutOfBounds() {
		let address = "tz1abc123"
		let token1 = Token(name: "Token1", symbol: "Token1", tokenType: .fungible, faVersion: .fa1_2, balance: TokenAmount.zero(), thumbnailURL: nil, tokenContractAddress: "KT1abc11111", tokenId: nil, nfts: nil, mintingTool: nil)
		let token2 = Token(name: "Token2", symbol: "Token2", tokenType: .fungible, faVersion: .fa1_2, balance: TokenAmount.zero(), thumbnailURL: nil, tokenContractAddress: "KT1abc22222", tokenId: nil, nfts: nil, mintingTool: nil)
		
		
		
		// Test basic setup
		let _ = TokenStateService.shared.addFavourite(forAddress: address, token: token1)
		let _ = TokenStateService.shared.addFavourite(forAddress: address, token: token2)
		
		let index1 = TokenStateService.shared.isFavourite(forAddress: address, token: token1) ?? -1
		let index2 = TokenStateService.shared.isFavourite(forAddress: address, token: token2) ?? -1
		
		XCTAssert(index1 == 1, index1.description)
		XCTAssert(index2 == 2, index2.description)
		
		
		
		// Test move too far forward, shouldn't move due to error
		let _ = TokenStateService.shared.moveFavouriteBalance(forAddress: address, forToken: token2, toIndex: 0)
		
		let moveIndex0_1 = TokenStateService.shared.isFavourite(forAddress: address, token: token1) ?? -1
		let moveIndex0_2 = TokenStateService.shared.isFavourite(forAddress: address, token: token2) ?? -1
		
		XCTAssert(moveIndex0_1 == 1, moveIndex0_1.description)
		XCTAssert(moveIndex0_2 == 2, moveIndex0_2.description)
		
		
		
		// Test move too far backwards, shouldn't move due to error
		let _ = TokenStateService.shared.moveFavouriteBalance(forAddress: address, forToken: token1, toIndex: 7)
		
		let moveIndex2_1 = TokenStateService.shared.isFavourite(forAddress: address, token: token1) ?? -1
		let moveIndex2_2 = TokenStateService.shared.isFavourite(forAddress: address, token: token2) ?? -1
		
		XCTAssert(moveIndex2_1 == 1, moveIndex2_1.description)
		XCTAssert(moveIndex2_2 == 2, moveIndex2_2.description)
		
		
		
		// Clean up before another test
		TokenStateService.shared.deleteAllCaches()
	}
	
	func testRemove() {
		let address = "tz1abc123"
		let token1 = Token(name: "Token1", symbol: "Token1", tokenType: .fungible, faVersion: .fa1_2, balance: TokenAmount.zero(), thumbnailURL: nil, tokenContractAddress: "KT1abc11111", tokenId: nil, nfts: nil, mintingTool: nil)
		let token2 = Token(name: "Token2", symbol: "Token2", tokenType: .fungible, faVersion: .fa1_2, balance: TokenAmount.zero(), thumbnailURL: nil, tokenContractAddress: "KT1abc22222", tokenId: nil, nfts: nil, mintingTool: nil)
		
		
		// Test basic setup
		let _ = TokenStateService.shared.addFavourite(forAddress: address, token: token1)
		let _ = TokenStateService.shared.addFavourite(forAddress: address, token: token2)
		
		let index1 = TokenStateService.shared.isFavourite(forAddress: address, token: token1) ?? -1
		let index2 = TokenStateService.shared.isFavourite(forAddress: address, token: token2) ?? -1
		
		XCTAssert(index1 == 1, index1.description)
		XCTAssert(index2 == 2, index2.description)
		
		
		// Test remove
		let _ = TokenStateService.shared.removeFavourite(forAddress: address, token: token1)
		
		let removeindex1 = TokenStateService.shared.isFavourite(forAddress: address, token: token1) ?? -1
		let removeindex2 = TokenStateService.shared.isFavourite(forAddress: address, token: token2) ?? -1
		
		XCTAssert(removeindex1 == -1, removeindex1.description)
		XCTAssert(removeindex2 == 1, removeindex2.description)
		
		
		
		// Clean up before another test
		TokenStateService.shared.deleteAllCaches()
	}
}