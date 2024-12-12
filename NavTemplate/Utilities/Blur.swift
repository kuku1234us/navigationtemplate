// Blur.swift

import SwiftUI

class UIBackdropView: UIView {
    override class var layerClass: AnyClass {
        NSClassFromString("CABackdropLayer") ?? CALayer.self
    }
}

struct Backdrop: UIViewRepresentable {
    func makeUIView(context: Context) -> UIBackdropView {
        UIBackdropView()
    }
    
    func updateUIView(_ uiView: UIBackdropView, context: Context) {}
}

struct Blur: View {
    var radius: CGFloat = 3
    var opaque: Bool = true
    
    var body: some View {
        Backdrop()
            .blur(radius: radius, opaque: opaque)
    }
}

extension View {
    func backgroundBlur(radius: CGFloat = 8, opaque: Bool = true) -> some View {
        self.background(Blur(radius: radius, opaque: opaque))
    }
}