import SwiftUI

struct HeaderStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .withSafeAreaTop()

            .backgroundBlur(radius: 10, opaque: true)
            .background(
                MeshGradient(
                    width: 3, height: 3,
                    points: [
                        [0.0,0.0], [0.5,0.0], [1.0,0.0],
                        [0.0,0.5], [0.5,0.5], [1.0,0.5],
                        [0.0,1.0], [0.5,1.0], [1.0,1.0]
                    ],
                    colors: [
                        Color("Background"),Color("Background"),.black,
                        .blue,Color("Background"),Color("Background"),
                        .blue,.blue,Color("Background"),                    
                    ]
                )
                .opacity(0.1)
            )
    }
}

extension View {
    func headerStyle() -> some View {
        modifier(HeaderStyle())
    }
} 