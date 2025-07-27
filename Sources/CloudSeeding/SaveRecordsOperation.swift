//
//  SaveRecordsOperation.swift
//  CloudSeeding
//
//  Created by Ben Gottlieb on 7/26/25.
//

import Foundation
import CloudKit

class SaveRecordsOperation: CKModifyRecordsOperation, @unchecked Sendable {
	var errors: [Error] = []
	
	func save(to database: CKDatabase) async throws {
		
		let _: Void = try await withUnsafeThrowingContinuation { continuation in
			self.perRecordSaveBlock = { record, result in
				switch result {
				case .success:
					continuation.resume()
				
				case .failure(let error):
					continuation.resume(throwing: error)
				}
			}
			qualityOfService = .userInitiated
			database.add(self)
		}
	}
}
