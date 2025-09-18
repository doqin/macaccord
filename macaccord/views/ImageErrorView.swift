struct ImageErrorView: View {
    var body: some View {
        Rectangle()
            .fill(Color.gray)
            .overlay(Image(systemName: "xmark.octagon.fill").foregroundColor(.white))
    }
}