//
//  CalendarChooser.swift
//  SharedCalendar
//
//  Created by Philipp on 09.11.20.
//

import SwiftUI
import EventKitUI

struct CalendarChooser: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode

    let eventStore: EKEventStore

    @Binding var calendars: Set<EKCalendar>

    let selectionStyle: EKCalendarChooserSelectionStyle
    let displayStyle: EKCalendarChooserDisplayStyle
    let entityType: EKEntityType

    init(eventStore: EKEventStore,
         calendars: Binding<Set<EKCalendar>>,
         selectionStyle: EKCalendarChooserSelectionStyle,
         displayStyle: EKCalendarChooserDisplayStyle,
         entityType: EKEntityType = .event)
    {
        self.selectionStyle = selectionStyle
        self.displayStyle = displayStyle
        self.entityType = entityType
        self.eventStore = eventStore
        self._calendars = calendars
    }

    func makeUIViewController(context: Context) -> UINavigationController {
        let vc = EKCalendarChooser(selectionStyle: selectionStyle,
                                   displayStyle: displayStyle,
                                   entityType: entityType,
                                   eventStore: eventStore)
        vc.selectedCalendars = calendars
        vc.showsDoneButton = true
        vc.showsCancelButton = true
        vc.delegate = context.coordinator
        return UINavigationController(rootViewController: vc)
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, EKCalendarChooserDelegate {

        let parent: CalendarChooser

        init(_ parent: CalendarChooser) {
            self.parent = parent
        }

        func calendarChooserDidCancel(_ calendarChooser: EKCalendarChooser) {
            parent.presentationMode.wrappedValue.dismiss()
        }

        func calendarChooserDidFinish(_ calendarChooser: EKCalendarChooser) {
            parent.calendars = calendarChooser.selectedCalendars
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct CalendarChooser_Previews: PreviewProvider {
    static var previews: some View {
        CalendarChooser(eventStore: .init(), calendars: .constant(.init([])),
                        selectionStyle: .multiple, displayStyle: .writableCalendarsOnly, entityType: .event)
    }
}
