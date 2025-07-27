//
//  SaveRecordOperation.swift
//  CloudSeeding
//
//  Created by Ben Gottlieb on 7/26/25.
//

import Foundation
import CloudKit

class SaveRecordOperation: CKModifyRecordsOperation, @unchecked Sendable {
	convenience init(record: CKRecord) {
		self.init(recordsToSave: [record])
	}
	
	var errors: [Error] = []
	
	func save(to database: CKDatabase) async throws -> CKRecord {
		
		 try await withUnsafeThrowingContinuation { continuation in
			self.perRecordSaveBlock = { recordID, result in
				switch result {
				case .success(let newRecord):
					continuation.resume(returning: newRecord)
				
				case .failure(let error):
					continuation.resume(throwing: error)
				}
			}
			qualityOfService = .userInitiated
			database.add(self)
		}
	}
}
