//
//  SearchFromRestApi.swift
//  SearchApis
//
//  Created by Thibault Wittemberg on 21/08/2022.
//

import Foundation

@Sendable func searchFromRestApi(query: String) async throws -> [Entry] {
  guard let url = URL(string: "https://api.publicapis.org/entries?title=\(query)") else {
    throw NSError(domain: "network", code: 1)
  }

  let (data, response) = try await URLSession.shared.data(from: url)

  guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
    throw NSError(domain: "network", code: 2)
  }

  let result = try JSONDecoder().decode(Response.self, from: data)
  return result.entries
}
