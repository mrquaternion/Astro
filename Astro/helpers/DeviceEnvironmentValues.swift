//
//  DeviceEnvironmentValues.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-22.
//

import SwiftUI

private struct IsPhoneEnvironmentKey: EnvironmentKey {
    /// Whether the current device is an iPhone.
    static let defaultValue: Bool = DeviceIdiom.isPhone
}

private struct IsPadEnvironmentKey: EnvironmentKey {
    /// Whether the current device is an iPad.
    static let defaultValue: Bool = DeviceIdiom.isPad
}

private struct IsLandscapeEnvironmentKey: EnvironmentKey {
    /// Whether the current interface space is wider than it is tall.
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    /// Whether the current device is an iPhone.
    var isPhone: Bool {
        get { self[IsPhoneEnvironmentKey.self] }
        set { self[IsPhoneEnvironmentKey.self] = newValue }
    }
    
    /// Whether the current device is an iPad.
    var isPad: Bool {
        get { self[IsPadEnvironmentKey.self] }
        set { self[IsPadEnvironmentKey.self] = newValue }
    }
    
    /// Whether the current interface space is wider than it is tall.
    var isLandscape: Bool {
        get { self[IsLandscapeEnvironmentKey.self] }
        set { self[IsLandscapeEnvironmentKey.self] = newValue }
    }
}

enum DeviceIdiom {
    /// Whether the current device is an iPhone.
    static var isPhone: Bool {
        #if os(iOS)
        UIDevice.current.userInterfaceIdiom == .phone
        #else
        false
        #endif
    }
    
    /// Whether the current device is an iPad.
    static var isPad: Bool {
        #if os(iOS)
        UIDevice.current.userInterfaceIdiom == .pad
        #else
        false
        #endif
    }
}

extension CGSize {
    /// Whether this size represents a landscape interface.
    var isLandscape: Bool {
        width > height
    }
}

extension View {
    /// Full screen cover instead of a sheet.
    @ViewBuilder
    func conditionalPresentation<Item: Identifiable>(
        item: Binding<Item?>,
        isPad: Bool,
        @ViewBuilder content: @escaping (Item) -> some View
    ) -> some View {
        if isPad {
            self.fullScreenCover(item: item, content: content)
        } else {
            self.sheet(item: item, content: content)
        }
    }
    
    /// Inspector instead of a sheet.
    @ViewBuilder
    func conditionalPresentationAlt(
        isPresented: Binding<Bool>,
        isPad: Bool,
        @ViewBuilder content: @escaping () -> some View
    ) -> some View {
        if isPad {
            self.inspector(isPresented: isPresented, content: content)
        } else {
            self.sheet(isPresented: isPresented, content: content)
        }
    }
}
