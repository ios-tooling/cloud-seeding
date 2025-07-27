//
//  File.swift
//  CloudSeeding
//
//  Created by Ben Gottlieb on 7/26/25.
//

import Foundation
import CloudKit

public enum CKRecordConflictHandlerResult: Sendable { case ignore, replace(CKRecord) }

public extension CKDatabase {
	func save(record: CKRecord) async throws {
		try await save(record: record) { _, _ in .ignore}
	}

	func save(record: CKRecord, conflicts: @escaping (CKRecord, Error) async -> CKRecordConflictHandlerResult) async throws {
		let op = SaveRecordsOperation(recordsToSave: [record])
		do {
			try await op.save(to: self)
		} catch let error as CKError {
			switch error.code {
			case .serverRecordChanged:
				if let serverRecord = error.userInfo[CKRecordChangedErrorServerRecordKey] as? CKRecord {
					switch await conflicts(serverRecord, error) {
					case .ignore: break
					case .replace(let newRecord): try await save(record: newRecord)
					}
					return
				}
				
			default: break
			}
			throw error
		} catch {
			throw error
		}
	}
	
	func fetchRecords(ofType type: CKRecord.RecordType, matching predicate: NSPredicate = .init(value: true), inZone: CKRecordZone.ID? = nil, keys: [CKRecord.FieldKey]? = nil, limit: Int = CKQueryOperation.maximumResults) async throws -> [CKRecord] {
		if await !CloudKitInterface.instance.isAvailable { throw CloudSeedingError.notAvailable }
		let query = CKQuery(recordType: type, predicate: predicate)
		do {
			var allResults: [CKRecord] = []
			var cursor: CKQueryOperation.Cursor?
			
			while true {
				let results: (matchResults: [(CKRecord.ID, Result<CKRecord, Error>)], queryCursor: CKQueryOperation.Cursor?)
				
				if let cursor {
					results = try await self.records(continuingMatchFrom: cursor)
				} else {
					results = try await self.records(matching: query, inZoneWith: inZone, desiredKeys: keys, resultsLimit: limit)
				}
				
				allResults += results.matchResults.compactMap { result in
					switch result.1 {
					case .success(let record): return record
					case .failure: return nil
					}
				}
				
				guard let next = results.queryCursor, allResults.count < limit else { break }
				cursor = next
			}
			return allResults
		} catch {
			
		}
		
		return []
	}
}
