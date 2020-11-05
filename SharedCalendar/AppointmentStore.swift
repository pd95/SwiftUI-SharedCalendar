//
//  AppointmentStore.swift
//  SharedCalendar
//
//  Created by Philipp on 04.11.20.
//

import EventKit

extension EKEvent {
    var appointment: Appointment {
        Appointment(id: eventIdentifier, title: title, startDate: startDate, endDate: endDate, notes: notes ?? "")
    }
}

class AppointmentStore: ObservableObject {
    var store = EKEventStore()
    var calendarAccessible = false

    static let constMyCalendarName = "Appointments"

    @UserDefault(key: "calendarIdentifier", defaultValue: "")
    private var calendarIdentifier: String

    var calendar: EKCalendar?

    @Published var appointments = [Appointment]()

    func prepare() {
        store.requestAccess(to: .event) { (success, error) in
            if let error = error {
                print("Error requesting access: \(error.localizedDescription)")
            }
            else {
                print("Request granted: \(success)")
                self.calendarAccessible = success

                // Get calendar
                let identifier = self.calendarIdentifier
                if !identifier.isEmpty {
                    print("Existing calendar: \(identifier)")
                    if let calendar = self.store.calendar(withIdentifier: identifier) {
                        self.calendar = calendar
                        print("Calendar loaded: \(calendar)")
                    }
                    else {
                        print("🔴 Calendar not loaded!!")
                    }
                }
                if self.calendar == nil {
                    // Get sources for calendar
                    for source in self.store.sources {
                        print(source)
                    }

                    let localSource = self.store.sources.first(where: { $0.sourceType == .local }) ?? self.store.sources.first!

                    // Create local calendar
                    let newCalendar = EKCalendar(for: .event, eventStore: self.store)
                    newCalendar.title = "Client Appointments"
                    newCalendar.source = localSource
                    self.calendarIdentifier = newCalendar.calendarIdentifier
                    self.calendar = newCalendar
                    print("🟡 New calendar created: \(newCalendar)")
                    do {
                        try self.store.saveCalendar(newCalendar, commit: true)
                    } catch {
                        print("🔴 Exception occurred: \(error.localizedDescription)")
                        print("do something, please!")
                    }
                }

                if self.calendar != nil {
                    self.fetchAppointments()
                }
            }
        }
    }

    func fetchAppointments() {
        guard let calendar = calendar else {
            fatalError("Calendar should have been initialized")
        }
        let startDate = Calendar.current.startOfDay(for: Date())
        let endDate = Calendar.current.date(byAdding: DateComponents(day: 365), to: startDate)!
        let predicate = store.predicateForEvents(withStart: startDate, end: endDate, calendars: [calendar])

        let events = store.events(matching: predicate)

        DispatchQueue.main.async {
            self.appointments = events.map(\.appointment)
        }
    }

    func event(forAppointment appointment: Appointment) -> EKEvent? {
        return store.event(withIdentifier: appointment.id)
    }

    func commit() {
        do {
            try store.commit()
        } catch {
            print("🔴 Exception occurred: \(error.localizedDescription)")
            print("do something, please!")
        }
    }

    func createAppointment(_ title: String, on startDate: Date, for duration: TimeInterval) {
        let event = EKEvent(eventStore: store)
        event.title = title
        let endDate = startDate.addingTimeInterval(duration * 60)
        event.availability = .busy
        event.startDate = startDate
        event.endDate = endDate
        event.calendar = calendar

        event.addAlarm(EKAlarm(relativeOffset: -15*60))  // Add alarm 15 minutes before event date

        do {
            try store.save(event, span: .thisEvent, commit: true)
        } catch {
            print("🔴 Exception occurred: \(error.localizedDescription)")
            print("do something, please!")
        }

        fetchAppointments()
    }
}

