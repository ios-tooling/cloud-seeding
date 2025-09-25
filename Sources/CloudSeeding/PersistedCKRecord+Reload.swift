//
//  PersistedCKRecord.swift
//  CloudSeeding
//
//  Created by Ben Gottlieb on 7/25/25.
//

import CloudKit
import Suite
import SwiftData

enum PersistedCKRecordRefreshError: Error { case recordNotInserted, recordNotFound, loadRecordFailed }

public extension PersistedCKRecord {
	
	func reloadFromCloud() async throws {
		guard let modelContext else { throw PersistedCKRecordRefreshError.recordNotInserted }
		guard let cloudRecord = try await CloudKitInterface.instance.container.privateCloudDatabase.fetchRecords(withIDs: [ckRecordID]).first else { throw PersistedCKRecordRefreshError.recordNotFound }
				
		if !load(fromCloud: cloudRecord, context: modelContext) {
			throw PersistedCKRecordRefreshError.loadRecordFailed
		}
	}
}

