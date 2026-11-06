import SwiftUI

extension View {
    func screenBackground(_ imageName: String, opacity: Double = 0.3, fit: Bool = false, topOffset: CGFloat = 0) -> some View {
        self.scrollContentBackground(.hidden)
            .background {
                if UIImage(named: imageName) == nil {
                    Color(.systemGroupedBackground).ignoresSafeArea()
                } else {
                    GeometryReader { geo in
                        ZStack(alignment: .top) {
                            Image(imageName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: geo.size.width, height: geo.size.height)
                                .scaleEffect(fit ? 1.15 : 1)
                                .blur(radius: fit ? 30 : 0)
                                .clipped()

                            if fit {
                                Image(imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: geo.size.width)
                                    .mask(
                                        LinearGradient(stops: [
                                            .init(color: .clear, location: 0),
                                            .init(color: .black, location: 0.08),
                                            .init(color: .black, location: 0.92),
                                            .init(color: .clear, location: 1)
                                        ], startPoint: .top, endPoint: .bottom)
                                    )
                                    .padding(.top, topOffset)
                            }
                        }
                        .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                        .clipped()
                        .overlay(Color.gray.opacity(opacity))
                    }
                    .ignoresSafeArea()
                }
            }
    }
}
