// Widget.swift

import SwiftUI

protocol Widget: View, Identifiable {
    associatedtype ID = UUID
    var id: ID { get }
}
