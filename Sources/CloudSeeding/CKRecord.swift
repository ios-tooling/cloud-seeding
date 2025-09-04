//
//  CKRecord.swift
//  CloudSeeding
//
//  Created by Ben Gottlieb on 8/15/25.
//

import Foundation
import CloudKit

public extension CKRecord {
	var createdByRecordID: String? {
		let name = self.creatorUserRecordID?.recordName
		return name == CKCurrentUserDefaultName ? CloudKitInterface.currentUserID : name
	}
}
