import SwiftUI

/// The dark panel with a thin border that holds most content.
///
/// It's generic over `Content` so it can wrap *any* views:
///     CockpitCard { Text("Hello") }
/// `@ViewBuilder` is what lets you pass several views inside the braces.
struct CockpitCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(Theme.Spacing.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Colors.surface, in: .rect(cornerRadius: Theme.Radius.card))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .strokeBorder(Theme.Colors.border, lineWidth: 1)
            }
    }
}

#Preview {
    CockpitCard {
        Text("Task").cockpitLabel()
        Text("Chem problem set").foregroundStyle(Theme.Colors.textPrimary)
    }
    .padding()
    .background(Theme.Colors.background)
}
