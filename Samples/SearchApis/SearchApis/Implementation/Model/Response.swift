//
//  Response.swift
//  SearchApis
//
//  Created by Thibault Wittemberg on 21/08/2022.
//

struct Response: Decodable {
  let count: Int
  let entries: [Entry]
}
