//
//  CloudKitInterface.swift
//  CloudSeeding
//
//  Created by Ben Gottlieb on 7/26/25.
//

import Foundation
import CloudKit

@MainActor public class CloudKitInterface {
	public static let instance = CloudKitInterface()
	
	public var isAvailable = false
	
	var tokens: [NSObjectProtocol] = []
	var container: CKContainer!
	
	init() {
	}
	
	public func setup(containerID: String?) {
		tokens.append(NotificationCenter.default.addObserver(forName: Notification.Name.CKAccountChanged, object: nil, queue: .main) { note in
			Task { await self.checkAccountStatus() }
		})
		
		container = containerID == nil ? CKContainer.default() : CKContainer(identifier: containerID!)
	}
	
	func checkAccountStatus() async {
		do {
			let status = try await container.accountStatus()
			
			switch status {
				
			case .couldNotDetermine:
				isAvailable = false
			case .available:
				isAvailable = true
			case .restricted:
				isAvailable = true
			case .noAccount:
				isAvailable = false
			case .temporarilyUnavailable:
				isAvailable = false
			@unknown default:
				break
			}
		} catch {
			print("Failed to check CloudKit account status: \(error)")
		}
	}

}
