//
//  EventView.swift
//  SharedCalendar
//
//  Created by Philipp on 05.11.20.
//

import SwiftUI
import EventKitUI

struct EventView: UIViewControllerRepresentable {
    let event: EKEvent

    let completion: (EKEventViewAction) -> Void

    func makeUIViewController(context: Context) -> UINavigationController {
        let vc = EKEventViewController()
        vc.event = event
        vc.allowsEditing = true
        vc.delegate = context.coordinator
        return UINavigationController(rootViewController: vc)
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject, EKEventViewDelegate {
        let parent: EventView

        init(_ parent: EventView) {
            self.parent = parent
        }

        func eventViewController(_ controller: EKEventViewController, didCompleteWith action: EKEventViewAction) {
            parent.completion(action)
        }
    }
}
