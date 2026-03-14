import SwiftUI

// MARK: - Анимированный градиент фона (плавное движение)

struct AnimatedGradientBackground: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        LinearGradient(
            colors: [
                Theme.gradientDark,
                Theme.gradientMid,
                Theme.gradientLight,
                Theme.gradientFuchsia
            ],
            startPoint: UnitPoint(x: 0.2 - phase * 0.15, y: 0.1),
            endPoint: UnitPoint(x: 0.85 + phase * 0.15, y: 0.95)
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                phase = 1
            }
        }
    }
}
