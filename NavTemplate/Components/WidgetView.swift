import SwiftUI

struct WidgetView: View {
    @ObservedObject var widget: BaseWidget
    
    var body: some View {
        if widget.isActive {
            widget.view
                .onAppear {
                    print("WidgetView appeared for \(type(of: widget))")
                }
                .onDisappear {
                    print("WidgetView disappeared for \(type(of: widget))")
                }
        }
    }
} 