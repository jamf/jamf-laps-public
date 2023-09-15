//
//  Logger.swift
//  Jamf LAPS
//
//  Copyright 2023, Jamf

import Foundation
import os.log

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!

    //Categories
    static let laps = Logger(subsystem: subsystem, category: "laps")  // added lnh
}
