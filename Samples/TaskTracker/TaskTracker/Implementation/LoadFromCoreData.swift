//
//  LoadFromCoreData.swift
//  TaskTracker
//
//  Created by Thibault Wittemberg on 16/02/2022.
//

import CoreData

@Sendable func loadFromCoreData(context: NSManagedObjectContext) async throws -> [Entry] {
  try await context.perform {
    let request = NSFetchRequest<TimeEntryEntity>(entityName: "TimeEntryEntity")
    request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
    let timeEntryEntities = try context.fetch(request)
    
    let entries = timeEntryEntities.compactMap { timeEntryEntity -> Entry? in
      guard
        let id = timeEntryEntity.identifier,
        let startDate = timeEntryEntity.startDate,
        let endDate = timeEntryEntity.endDate,
        let description = timeEntryEntity.content else {
        return nil
      }

      return Entry(id: id, startDate: startDate, endDate: endDate, description: description)
    }

    return entries
  }
}
