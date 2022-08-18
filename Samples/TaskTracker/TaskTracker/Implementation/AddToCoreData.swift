//
//  AddToCoreData.swift
//  TaskTracker
//
//  Created by Thibault Wittemberg on 16/02/2022.
//

import CoreData

@Sendable func addToCoreData(entry: Entry, context: NSManagedObjectContext) async throws -> Void {
  let timeEntryEntity = TimeEntryEntity(context: context)
  timeEntryEntity.identifier = entry.id
  timeEntryEntity.startDate = entry.startDate
  timeEntryEntity.endDate = entry.endDate
  timeEntryEntity.content = entry.description

  try await context.perform {
    try context.save()
  }
}
