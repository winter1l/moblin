import Foundation
@testable import Moblin
import SwiftUI
import Testing
import UIKit

@MainActor
struct ChzzkScreensSuite {
    private func render(
        _ name: String, view: some View, model: Model, parent: UIViewController
    ) async throws {
        let shown = NavigationStack { view }
            .environmentObject(model)
            .environment(\.locale, Locale(identifier: "ko_KR"))
            .environment(\.horizontalSizeClass, .compact)
            .preferredColorScheme(.light)
        let controller = UIHostingController(rootView: shown)
        parent.addChild(controller)
        let rect = CGRect(x: 0, y: 0, width: 430, height: name == "06-chat-sample" ? 300 : 730)
        controller.view.frame = rect
        parent.view.addSubview(controller.view)
        controller.didMove(toParent: parent)
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        try await Task.sleep(for: .milliseconds(800))
        controller.view.layoutIfNeeded()
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2
        format.opaque = true
        let data = UIGraphicsImageRenderer(bounds: rect, format: format).pngData { _ in
            controller.view.drawHierarchy(in: rect, afterScreenUpdates: true)
        }
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MoblinChzzkPreviewPNGs")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try data.write(to: dir.appendingPathComponent(name + ".png"))
        controller.willMove(toParent: nil)
        controller.view.removeFromSuperview()
        controller.removeFromParent()
    }

    @Test
    func capture() async throws {
        let model = try #require(MoblinApp.globalModel)
        let scene = try #require(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let parent = try #require(scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
            ?? scene.windows.first?.rootViewController)
        let wizard = CreateStreamWizard()
        wizard.platform = .chzzk
        wizard.name = "치지직"
        let stream = SettingsStream(name: "치지직")
        stream.enabled = true
        stream.audioBitrate = 128_000
        try await render("01-platform", view: StreamWizardSettingsView(model: model, createStreamWizard: wizard),
                         model: model, parent: parent)
        try await render("02-channel", view: StreamWizardChzzkSettingsView(model: model, createStreamWizard: wizard),
                         model: model, parent: parent)
        try await render("03-direct", view: StreamWizardNetworkSetupDirectSettingsView(model: model, createStreamWizard: wizard),
                         model: model, parent: parent)
        try await render("04-account", view: StreamChzzkSettingsView(model: model, stream: stream),
                         model: model, parent: parent)
        try await render("05-audio", view: StreamAudioSettingsView(stream: stream, bitrate: Float(stream.audioBitrate) / 1000),
                         model: model, parent: parent)
        let amount = "1,000"
        let gift = ChatHighlight(kind: .other, barColor: .mint, image: "gift.fill",
                                 titleSegments: makeChatPostTextSegments(text: String(localized: "Donated ₩\(amount)")))
        for (name, text, highlight) in [("예시시청자", "방송 소리 잘 들려요!", Optional<ChatHighlight>.none),
                                          ("예시후원자", "오늘 방송도 응원합니다.", gift)] {
            model.appendChatMessage(
                platform: .chzzk, messageId: nil, displayName: name, user: name,
                userId: nil, userColor: nil, userBadges: [], segments: makeChatPostTextSegments(text: text),
                timestamp: "12:00", timestampTime: .now, isAction: false, isSubscriber: false, isModerator: false,
                isOwner: false, bits: nil, highlight: highlight, live: false
            )
        }
        model.quickButtonChat.update()
        try await render("06-chat-sample", view: QuickButtonChatView(model: model, orientation: model.orientation,
                                                                    quickButtonChat: model.quickButtonChatState),
                         model: model, parent: parent)
    }
}
