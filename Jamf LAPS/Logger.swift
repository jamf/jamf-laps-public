//
//  Logger.swift
//  Jamf LAPS
//
//  Created by Richard Mallion on 07/05/2023.
//  Copyright 2023, Jamf

import Foundation
import os.log

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!

    //Categories
    static let laps = Logger(subsystem: subsystem, category: "laps")  // added lnh
}
