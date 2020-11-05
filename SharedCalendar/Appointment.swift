//
//  Appointment.swift
//  SharedCalendar
//
//  Created by Philipp on 04.11.20.
//

import Foundation

struct Appointment: Identifiable {

    var id: String

    var title: String
    var startDate: Date
    var duration: TimeInterval

    var endDate: Date {
        startDate.addingTimeInterval(duration)
    }

    var notes: String

    init(id: String = UUID().uuidString, title: String, startDate: Date, endDate: Date, notes: String) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.duration = endDate.distance(to: startDate)
        self.notes = notes
    }
}
