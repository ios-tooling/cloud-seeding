//
//  File.swift
//  CloudSeeding
//
//  Created by Ben Gottlieb on 7/26/25.
//

import Foundation
import CloudKit

extension CKDatabase {
	func save(record: CKRecord) async throws {
		let op = CKModifyRecordsOperation(recordsToSave: [record])
		try await op.save(to: self)
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
