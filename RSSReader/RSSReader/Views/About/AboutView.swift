import SwiftUI

struct AboutView: View {
    private let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let build   = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    var body: some View {
        VStack(spacing: 0) {
            // App-Icon + Name
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color.cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .shadow(color: .blue.opacity(0.4), radius: 12, y: 6)

                    Image(systemName: "dot.radiowaves.up.forward")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .padding(.top, 28)

                Text("RSSReader")
                    .font(.system(size: 22, weight: .bold))

                Text("Version \(version) (\(build))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Divider()
                .padding(.horizontal, 24)
                .padding(.top, 20)

            // Beschreibung
            VStack(alignment: .leading, spacing: 14) {
                Text("Nativer macOS RSS-Reader mit Widget, Menüleisten-Integration und Regelautomatisierung.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.secondary)

                Divider()

                // Links
                VStack(spacing: 10) {
                    linkRow(
                        icon: "chevron.left.forwardslash.chevron.right",
                        label: "Quellcode auf GitHub",
                        url: "https://github.com/hansy2/rss-reader-macos"
                    )
                    linkRow(
                        icon: "ladybug",
                        label: "Bug melden",
                        url: "https://github.com/hansy2/rss-reader-macos/issues/new"
                    )
                    linkRow(
                        icon: "star",
                        label: "Releases & Updates",
                        url: "https://github.com/hansy2/rss-reader-macos/releases"
                    )
                }

                Divider()

                // Lizenz & Credits
                VStack(spacing: 4) {
                    Text("MIT Lizenz · © 2026 hansy2")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Gebaut mit SwiftUI · SwiftData · FeedKit")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 28)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .frame(width: 360)
    }

    private func linkRow(icon: String, label: String, url: String) -> some View {
        Button {
            if let u = URL(string: url) { NSWorkspace.shared.open(u) }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundStyle(.blue)
                    .frame(width: 18)
                Text(label)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
