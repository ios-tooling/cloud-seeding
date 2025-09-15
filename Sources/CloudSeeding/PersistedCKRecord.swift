//
//  PersistedCKRecord.swift
//  CloudSeeding
//
//  Created by Ben Gottlieb on 7/25/25.
//

import CloudKit
import Suite
import SwiftData

public enum NewerRecord: String { case localNewer, serverNewer, unknownNewer }

public protocol PersistedCKRecord: CKRecordBased & PersistentModel, PresavablePersistentModel {
	var modifiedAt: Date { get set }
	var changeRecordedAt: Date? { get set }
	var syncEngineID: String { get set }
	init()
	func resolveConflict(with cloudRecord: CKRecord, newer: NewerRecord, context: ModelContext)
	func load(fromCloud record: CKRecord, context: ModelContext) -> Bool
	func presave()
	func removeFromContext()
}

public extension PersistedCKRecord {
	init?(record: CKRecord, context: ModelContext) {
		self.init()
		syncEngineID = record.recordID.recordName
		self.modifiedAt = record[.modifiedAt] ?? record.modificationDate ?? .now
		if !load(fromCloud: record, context: context) { return nil }
	}

	func newerRecord(than cloudRecord: CKRecord) -> NewerRecord {
		guard let cloudModifiedAt = cloudRecord.modificationDate else { return .unknownNewer }
		if cloudModifiedAt > modifiedAt { return .serverNewer }
		return .localNewer
	}

	func clearModifiedAt() {
		changeRecordedAt = nil
	}
	
	func setModifiedAt() {
		changeRecordedAt = .now
		modifiedAt = .now
	}
	
	func presave() { }
	
	func reportedSave() {
		guard let modelContext else {
			print("Trying to save a record without a model context")
			return
		}
		
		do {
			modelContext.presave()
			try modelContext.save()
		} catch {
			print("Failed to save record: \(type(of: self)): \(error.localizedDescription)")
		}
	}
	
	func removeFromContext() {
		modelContext?.delete(self)
	}
}

