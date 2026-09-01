import SwiftUI
import AVKit
import AVFoundation

struct VideoPlayerView: View {
    let url: String
    let title: String
    @Environment(\.presentationMode) var presentationMode
    @State private var player: AVPlayer?
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)

                if let player = player {
                    VideoPlayer(player: player)
                        .edgesIgnoringSafeArea(.all)
                        .onAppear {
                            player.play()
                        }
                } else if showError {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding()
                        Button(action: {
                            loadVideo()
                        }) {
                            Text("重试")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                    }
                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            }
            .navigationBarTitle(title, displayMode: .inline)
            .navigationBarItems(trailing: Button(action: {
                player?.pause()
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
            })
            .navigationBarItems(leading: Button(action: {
                player?.pause()
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.down")
                    .foregroundColor(.white)
            })
        }
        .onAppear {
            loadVideo()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }

    private func loadVideo() {
        showError = false
        errorMessage = ""

        guard let videoURL = URL(string: url) else {
            showError = true
            errorMessage = "无效的视频地址"
            return
        }

        let playerItem = AVPlayerItem(url: videoURL)

        let newPlayer = AVPlayer(playerItem: playerItem)
        newPlayer.allowsExternalPlayback = true
        newPlayer.usesExternalPlaybackWhileExternalScreenIsActive = true

        self.player = newPlayer
    }
}

struct LocalVideoPlayerView: View {
    let fileURL: URL
    let title: String
    @Environment(\.presentationMode) var presentationMode
    @State private var player: AVPlayer?

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)

                if let player = player {
                    VideoPlayer(player: player)
                        .edgesIgnoringSafeArea(.all)
                        .onAppear {
                            player.play()
                        }
                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            }
            .navigationBarTitle(title, displayMode: .inline)
            .navigationBarItems(trailing: Button(action: {
                player?.pause()
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
            })
        }
        .onAppear {
            let newPlayer = AVPlayer(url: fileURL)
            newPlayer.allowsExternalPlayback = true
            self.player = newPlayer
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
}
