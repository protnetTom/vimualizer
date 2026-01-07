import SwiftUI

struct HudView: View {
    @EnvironmentObject var logic: VimLogic
    
    var body: some View {
        if logic.isHudEnabled {
            VStack(spacing: 12) {
                // Main Buffer Card
                VStack(spacing: 8) {
                    HStack {
                        Text(logic.currentState)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(red: 1, green: 0.9, blue: 0.4)) // Gold Title Color
                        
                        Spacer()
                    }
                    
                    HStack {
                        Spacer()
                        Text(logic.keyHistory.joined(separator: " "))
                            .font(.system(size: 24, weight: .regular, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    
                    if !logic.currentActionDescription.isEmpty {
                        HStack {
                            Spacer()
                            Text(logic.currentActionDescription)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 0.15, green: 0.15, blue: 0.15).opacity(0.95))
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .frame(width: 550) // Fixed width buffer
                
                // Drag Handle (Optional Visual)
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 4)
            }
            .padding()
        } else {
            EmptyView()
        }
    }
}
