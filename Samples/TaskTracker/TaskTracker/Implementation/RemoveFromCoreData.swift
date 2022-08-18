//
//  RemoveFromCoreData.swift
//  TaskTracker
//
//  Created by Thibault Wittemberg on 27/02/2022.
//

import CoreData

@Sendable func removeFromCoreData(entries: [Entry], context: NSManagedObjectContext) async throws -> Void {
  let entryIds = entries.map { $0.id }
  let request = NSFetchRequest<TimeEntryEntity>(entityName: "TimeEntryEntity")
  let predicate = NSPredicate(format: "identifier IN %@", entryIds)
  request.predicate = predicate
  request.includesPropertyValues = false
  
  try await context.perform {
    let entriesToRemove = try context.fetch(request)
    for entry in entriesToRemove {
      context.delete(entry)
    }
    try context.save()
  }
}
