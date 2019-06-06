//
//  SearchableRecord.swift
//  Continuum
//
//  Created by Will morris on 6/5/19.
//  Copyright © 2019 devmtn. All rights reserved.
//

import Foundation

protocol SearchableRecord {
    func matches(searchTerm: String) -> Bool
}
