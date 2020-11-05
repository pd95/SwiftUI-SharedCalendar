//
//  UserDefault.swift
//  SharedCalendar
//
//  Created by Philipp on 05.11.20.
//

import Foundation

@propertyWrapper
struct UserDefault<Value> {

    let key: String
    let defaultValue: Value
    var storage: UserDefaults

    init(key: String, defaultValue: Value, storage: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.storage = storage
    }

    var wrappedValue: Value {
        get {
            let value: Value? = storage.value(forKey: key) as? Value
            return value ?? defaultValue
        }
        set {
            storage.setValue(newValue, forKey: key)
        }
    }
}
