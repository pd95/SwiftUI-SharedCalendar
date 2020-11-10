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

    @UserDefault(key: "calendarIdentifier", defaultValue: "")
    private var calendarIdentifier: String

    @Published var calendar: EKCalendar? {
        didSet {
            calendarIdentifier = calendar?.calendarIdentifier ?? ""
            fetchAppointments()
        }
    }
    @Published var error: Error?

    @Published var appointments = [Appointment]()

    func prepare() {
        store.requestAccess(to: .event) { (success, error) in
            if let error = error {
                print("Error requesting access: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.error = error
                }
            }
            else {
                print("Request granted: \(success)")
                self.calendarAccessible = success

                // Get calendar
                let identifier = self.calendarIdentifier
                if !identifier.isEmpty {
                    print("Existing calendar: \(identifier)")
                    if let calendar = self.store.calendar(withIdentifier: identifier) {
                        print("Calendar loaded: \(calendar)")
                        DispatchQueue.main.async {
                            self.calendar = calendar
                        }
                    }
                    else {
                        print("🔴 Calendar not loaded!!")
                    }
                }
            }
        }
    }

    func fetchAppointments() {
        guard let calendar = calendar else {
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            let startDate = Calendar.current.startOfDay(for: Date())
            let endDate = Calendar.current.date(byAdding: DateComponents(day: 365), to: startDate)!
            let predicate = self.store.predicateForEvents(withStart: startDate, end: endDate, calendars: [calendar])

            let events = self.store.events(matching: predicate)

            DispatchQueue.main.async {
                self.appointments = events.map(\.appointment)
            }
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

