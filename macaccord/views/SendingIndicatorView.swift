//
//  SendingIndicator.swift
//  macaccord
//
//  Created by đỗ quyên on 18/9/25.
//


// MARK: - Sending indicator
struct SendingIndicatorView: View {
    @Binding var isSending: Bool
    
    var body: some View {
        VStack {
            Spacer()
            if isSending {
                // Sending indicator
                HStack(spacing: 2) {
                    Text("Sending")
                        .font(.callout)
                        .foregroundColor(.secondary)
                    ProgressView()
                        .frame(width: 20, height: 20)
                        .scaleEffect(0.5)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.blue)
                .cornerRadius(8)
                .padding(4)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.bouncy(duration: 0.4), value: isSending)
    }
}
