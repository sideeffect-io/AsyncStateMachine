//
//  Entry.swift
//  SearchApis
//
//  Created by Thibault Wittemberg on 21/08/2022.
//

struct Entry: Decodable, Equatable {
  let api: String
  let description: String
  let link: String

  enum CodingKeys: String, CodingKey {
    case api = "API"
    case description = "Description"
    case link = "Link"
  }
}
