// Blur.swift

import SwiftUI

public class UIBackdropView: UIView {
    override public class var layerClass: AnyClass {
        NSClassFromString("CABackdropLayer") ?? CALayer.self
    }
}

public struct Backdrop: UIViewRepresentable {
    public init() {}
    
    public func makeUIView(context: Context) -> UIBackdropView {
        UIBackdropView()
    }
    
    public func updateUIView(_ uiView: UIBackdropView, context: Context) {}
}

public struct Blur: View {
    var radius: CGFloat = 3
    var opaque: Bool = true
    
    public init(radius: CGFloat = 3, opaque: Bool = true) {
        self.radius = radius
        self.opaque = opaque
    }
    
    public var body: some View {
        Backdrop()
            .blur(radius: radius, opaque: opaque)
    }
}

public extension View {
    func backgroundBlur(radius: CGFloat = 8, opaque: Bool = true) -> some View {
        return self.background(Blur(radius: radius, opaque: opaque))
    }
}