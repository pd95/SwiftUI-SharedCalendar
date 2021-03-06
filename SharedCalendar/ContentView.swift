//
//  ContentView.swift
//  SharedCalendar
//
//  Created by Philipp on 04.11.20.
//

import SwiftUI
import EventKit
import EventKitUI

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct ContentView: View {

    @StateObject private var store = AppointmentStore()

    @State private var chooseCalendar = false
    @State private var title = ""
    @State private var startDate = Date().addingTimeInterval(10000)
    @State private var duration = 60
    @State private var infoForAppointment: Appointment?

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    var body: some View {
        Form {
            Section(header: Text("Calendar")) {
                Button(
                    action: {
                        chooseCalendar.toggle()
                    },
                    label: {
                        if let calendar = store.calendar {
                            Text(calendar.title)
                        }
                        else {
                            Text("Choose Calendar")
                        }
                    }
                )
                .sheet(isPresented: $chooseCalendar, content: {
                    CalendarChooser(
                        eventStore: store.store,
                        calendars: Binding(get: {
                            if let calendar = store.calendar {
                                return Set([calendar])
                            }
                            return Set([])
                        }, set: { (calendars: Set<EKCalendar>?) in
                            if let calendars = calendars {
                                store.calendar = calendars.first
                            }
                            else {
                                store.calendar = nil
                            }
                        }),
                        selectionStyle: .single,
                        displayStyle: .writableCalendarsOnly
                    )
                    .edgesIgnoringSafeArea(.all)
                })
            }

            Section(header: Text("New appointment:")) {
                TextField("Title", text: $title)
                DatePicker("Start", selection: $startDate, in: Calendar.current.startOfDay(for: Date())...)
                Stepper("Duration: \(duration)", value: $duration, in: 5...240, step: 5)
                Button("Add to Calendar") {
                    store.createAppointment(title, on: startDate, for: TimeInterval(duration))
                    title = ""
                    startDate += 90*60
                    UIApplication.shared.endEditing()
                }
                .disabled(title.isEmpty || startDate<Calendar.current.startOfDay(for: Date()))
            }
            .disabled(store.calendar == nil)

            Section(header: Text("Upcoming appointments")) {
                List(store.appointments) { appointment in
                    HStack {
                        Text(appointment.startDate, formatter: dateFormatter)
                        Text(appointment.title)
                            .font(.headline)

                        Spacer()

                        Button(action: { infoForAppointment = appointment }, label: {
                            Image(systemName: "info.circle")
                                .imageScale(.large)
                        })
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
            }
        }
        .sheet(item: $infoForAppointment, content: { (appointment: Appointment) in
            AppointmentView(appointment: appointment)
                .environmentObject(store)
        })
        .onAppear() {
            store.prepare()
        }
    }
}


struct AppointmentView: View {

    @EnvironmentObject var store: AppointmentStore
    @Environment(\.presentationMode) var presentationMode
    let appointment: Appointment

    var body: some View {
        if let event = store.event(forAppointment: appointment) {
            EventView(event: event) { (action) in
                presentationMode.wrappedValue.dismiss()
                if action == .deleted {
                    store.fetchAppointments()
                }
            }
            .edgesIgnoringSafeArea(.all)
        }
        else {
            EmptyView()
                .onAppear() {
                    presentationMode.wrappedValue.dismiss()
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
