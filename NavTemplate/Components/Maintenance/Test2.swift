import SwiftUI

struct Test2: View {
    var body: some View {
        VStack {
            Text("The following is an image:")
                .padding()

            ViewToImage(
                VStack(alignment: .leading, spacing: 10) {
                }
                .padding()
            )
        }
    }
}
