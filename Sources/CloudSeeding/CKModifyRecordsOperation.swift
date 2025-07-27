//
//  File.swift
//  CloudSeeding
//
//  Created by Ben Gottlieb on 7/26/25.
//

import Foundation
import CloudKit

extension CKModifyRecordsOperation {
	func save(to database: CKDatabase) async throws {
		return try await withUnsafeThrowingContinuation { continuation in
			self.modifyRecordsResultBlock = { result in
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
