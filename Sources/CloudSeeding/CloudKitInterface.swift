//
//  CloudKitInterface.swift
//  CloudSeeding
//
//  Created by Ben Gottlieb on 7/26/25.
//

import Foundation
import CloudKit
import Combine

@MainActor @Observable public class CloudKitInterface {
	public static let instance = CloudKitInterface()
	
	public private(set) var isAvailable = false
	nonisolated static public var currentUserID: CKRecord.ID? { currentUserIDValue.value }
	nonisolated static let currentUserIDValue = CurrentValueSubject<CKRecord.ID?, Never>(nil)
	
	var tokens: [NSObjectProtocol] = []
	var containerID: String?
	public var container: CKContainer!
	
	private init() { }
	
	public func setup(containerID: String?) {
		tokens.append(NotificationCenter.default.addObserver(forName: Notification.Name.CKAccountChanged, object: nil, queue: .main) { note in
			Task { await self.checkAccountStatus() }
		})
		
		self.containerID = containerID
		container = containerID == nil ? CKContainer.default() : CKContainer(identifier: containerID!)
		Task { await checkAccountStatus() }
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

			if isAvailable {
				Self.currentUserIDValue.value = try await container.userRecordID()
				print("Signed in as: \(Self.currentUserID?.recordName ?? "??")")
			}
		} catch {
			print("Failed to check CloudKit account status: \(error)")
		}
	}

}
