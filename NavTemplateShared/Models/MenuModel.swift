// .NavTemplateShared/Models/MenuModel.swift

import Foundation
import SwiftUI

public struct MenuBarItem: Identifiable {
    public let id: Int
    public let name: String
    public let unselectedIcon: String
    public let selectedIcon: String
    public let targetView: AnyView
    public var sortOrder: Int
    
    public init(
        id: Int,
        name: String,
        unselectedIcon: String,
        selectedIcon: String,
        targetView: AnyView,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.unselectedIcon = unselectedIcon
        self.selectedIcon = selectedIcon
        self.targetView = targetView
        self.sortOrder = sortOrder
    }
}

public class MenuModel: ObservableObject {
    public static let shared = MenuModel()
    private let defaults = UserDefaults.standard
    private let menuOrderKey = "MenuItemOrder"
    
    @Published public private(set) var menuOrder: [Int: Int] = [:]
    @Published public private(set) var menuItems: [MenuBarItem] = []
    
    private init() {
        loadMenuOrder()
    }
    
    public func setMenuItems(_ items: [MenuBarItem]) {
        // Use DispatchQueue.main.async to avoid publishing during view updates
        DispatchQueue.main.async {
            // Store menu items from HomePage
            self.menuItems = items.map { item in
                // Create new items with EmptyView for settings display
                MenuBarItem(
                    id: item.id,
                    name: item.name,
                    unselectedIcon: item.unselectedIcon,
                    selectedIcon: item.selectedIcon,
                    targetView: AnyView(EmptyView()),
                    sortOrder: item.sortOrder
                )
            }
        }
    }
    
    private func loadMenuOrder() {
        if let savedOrder = defaults.dictionary(forKey: menuOrderKey) as? [String: Int] {
            menuOrder = savedOrder.reduce(into: [:]) { result, item in
                if let id = Int(item.key) {
                    result[id] = item.value
                }
            }
        }
    }
    
    public func sortMenuItems(_ items: [MenuBarItem]) -> [MenuBarItem] {
        var indexedItems = items.enumerated().map { (index, item) -> (Int, MenuBarItem) in
            var itemWithOrder = item
            itemWithOrder.sortOrder = menuOrder[item.id] ?? index
            return (index, itemWithOrder)
        }
        
        // Sort by sortOrder, falling back to original index for stability
        indexedItems.sort { (a, b) in
            let (aIndex, aItem) = a
            let (bIndex, bItem) = b
            
            // If both have saved orders, use them
            if let aOrder = menuOrder[aItem.id],
               let bOrder = menuOrder[bItem.id] {
                return aOrder < bOrder
            }
            
            // If only one has saved order, put it first
            if menuOrder[aItem.id] != nil { return true }
            if menuOrder[bItem.id] != nil { return false }
            
            // If neither has saved order, maintain original order
            return aIndex < bIndex
        }
        
        return indexedItems.map { $0.1 }
    }
    
    public func saveMenuOrder(_ items: [MenuBarItem]) {
        let orderDict = items.reduce(into: [:]) { dict, item in
            dict[String(item.id)] = item.sortOrder
        }
        print("orderDict: \(orderDict)")
        
        defaults.set(orderDict, forKey: menuOrderKey)
        loadMenuOrder()
    }
}
