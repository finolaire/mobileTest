//
//  SleepOverlayViewController.swift
//  EnglishSentence
//
//  全屏循环视频 sleep_animation（静音、fill、不可交互）+ sleep_audio.mp3；
//  交互与生命周期与 EyesOverlayViewController 一致。
//

import AVFoundation
import SnapKit
import UIKit

final class SleepOverlayViewController: UIViewController {

    private let videoContainerView: UIView = {
        let v = UIView()
        v.backgroundColor = .black
        v.isUserInteractionEnabled = false
        v.clipsToBounds = true
        return v
    }()

    private var player: AVQueuePlayer?
    private var playerLayer: AVPlayerLayer?
    private var playerLooper: AVPlayerLooper?

    /// 控制条未显示时：整屏点击 → 暂停
    private let pauseTapRecognizer = UITapGestureRecognizer()

    /// 控制条显示时：铺满底层，点击 → 继续播放并隐藏按钮
    private let resumeBackgroundControl: UIControl = {
        let c = UIControl()
        c.backgroundColor = .clear
        c.isHidden = true
        return c
    }()

    private let playButton: UIButton = {
        let b = UIButton(type: .system)
        let cfg = UIImage.SymbolConfiguration(pointSize: 36, weight: .medium)
        b.setImage(UIImage(systemName: "play.circle.fill", withConfiguration: cfg), for: .normal)
        b.tintColor = .white
        b.isHidden = true
        return b
    }()

    private let exitButton: UIButton = {
        let b = UIButton(type: .system)
        let cfg = UIImage.SymbolConfiguration(pointSize: 36, weight: .medium)
        b.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: cfg), for: .normal)
        b.tintColor = .white
        b.isHidden = true
        return b
    }()

    private var audioPlayer: AVAudioPlayer?
    private var controlsVisible = false
    /// 用户主动暂停；锁屏导致的系统暂停不算
    private var isUserPaused = false
    /// 已释放媒体，禁止再 play / 响应前台通知
    private var isTornDown = false
    private var lifecycleObservers: [NSObjectProtocol] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        view.addSubview(videoContainerView)
        view.addSubview(resumeBackgroundControl)
        view.addSubview(playButton)
        view.addSubview(exitButton)

        videoContainerView.snp.makeConstraints { $0.edges.equalToSuperview() }
        resumeBackgroundControl.snp.makeConstraints { $0.edges.equalToSuperview() }

        playButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview().offset(-48)
            make.centerY.equalToSuperview()
        }
        exitButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview().offset(48)
            make.centerY.equalTo(playButton)
        }

        pauseTapRecognizer.addTarget(self, action: #selector(handlePauseTap))
        view.addGestureRecognizer(pauseTapRecognizer)

        resumeBackgroundControl.addTarget(self, action: #selector(resumeAndHideControls), for: .touchUpInside)
        playButton.addTarget(self, action: #selector(resumeAndHideControls), for: .touchUpInside)
        exitButton.addTarget(self, action: #selector(exitTapped), for: .touchUpInside)

        setupVideoPlayer()
        registerLifecycleObservers()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !isTornDown else { return }
        playerLayer?.frame = videoContainerView.bounds
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !isTornDown else { return }
        startAudioIfNeeded()
        if !isUserPaused {
            player?.play()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard isBeingDismissed || isMovingFromParent else { return }
        tearDownMedia()
    }

    deinit {
        lifecycleObservers.forEach { NotificationCenter.default.removeObserver($0) }
        lifecycleObservers.removeAll()
        audioPlayer?.stop()
        audioPlayer = nil
        player?.pause()
        playerLooper = nil
        player = nil
    }

    // MARK: - Lifecycle observers (main queue)

    private func registerLifecycleObservers() {
        let center = NotificationCenter.default
        let onForeground: (Notification) -> Void = { [weak self] _ in
            self?.resumeAfterForegroundIfNeeded()
        }
        lifecycleObservers = [
            center.addObserver(
                forName: UIApplication.willEnterForegroundNotification,
                object: nil,
                queue: .main,
                using: onForeground
            ),
            center.addObserver(
                forName: UIApplication.didBecomeActiveNotification,
                object: nil,
                queue: .main,
                using: onForeground
            ),
            center.addObserver(
                forName: AVAudioSession.interruptionNotification,
                object: AVAudioSession.sharedInstance(),
                queue: .main
            ) { [weak self] note in
                self?.handleAudioSessionInterruption(note)
            }
        ]
    }

    private func removeLifecycleObservers() {
        lifecycleObservers.forEach { NotificationCenter.default.removeObserver($0) }
        lifecycleObservers.removeAll()
    }

    private func resumeAfterForegroundIfNeeded() {
        assert(Thread.isMainThread)
        guard !isTornDown, isViewLoaded, view.window != nil, !isUserPaused else { return }
        playerLayer?.frame = videoContainerView.bounds
        player?.play()
        if let audioPlayer, !audioPlayer.isPlaying {
            audioPlayer.play()
        }
    }

    private func handleAudioSessionInterruption(_ notification: Notification) {
        assert(Thread.isMainThread)
        guard !isTornDown else { return }
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        switch type {
        case .began:
            player?.pause()
            audioPlayer?.pause()
        case .ended:
            guard !isUserPaused else { return }
            let options = (info[AVAudioSessionInterruptionOptionKey] as? UInt)
                .flatMap(AVAudioSession.InterruptionOptions.init(rawValue:)) ?? []
            if options.contains(.shouldResume) || options.isEmpty {
                resumeAfterForegroundIfNeeded()
            }
        @unknown default:
            break
        }
    }

    // MARK: - Media setup / pause / resume / release

    private func resourceURL(name: String, ext: String) -> URL? {
        if let u = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Resources/Media") { return u }
        if let u = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Resource") { return u }
        return Bundle.main.url(forResource: name, withExtension: ext)
    }

    private func setupVideoPlayer() {
        guard let url = resourceURL(name: "sleep_animation", ext: "mp4") else { return }

        let item = AVPlayerItem(url: url)
        let queuePlayer = AVQueuePlayer()
        queuePlayer.isMuted = true
        playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: item)
        player = queuePlayer

        let layer = AVPlayerLayer(player: queuePlayer)
        layer.videoGravity = .resizeAspectFill
        layer.frame = videoContainerView.bounds
        videoContainerView.layer.addSublayer(layer)
        playerLayer = layer
    }

    private func startAudioIfNeeded() {
        guard audioPlayer == nil else {
            if !isUserPaused, audioPlayer?.isPlaying == false {
                audioPlayer?.play()
            }
            return
        }
        guard let url = resourceURL(name: "sleep_audio", ext: "mp3") else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            audioPlayer = player
            if !isUserPaused {
                player.play()
            }
        } catch {
            audioPlayer = nil
        }
    }

    private func pausePlayback() {
        assert(Thread.isMainThread)
        guard !isTornDown else { return }
        isUserPaused = true
        audioPlayer?.pause()
        player?.pause()
    }

    private func resumePlayback() {
        assert(Thread.isMainThread)
        guard !isTornDown else { return }
        isUserPaused = false
        audioPlayer?.play()
        player?.play()
    }

    private func tearDownMedia() {
        assert(Thread.isMainThread)
        guard !isTornDown else { return }
        isTornDown = true

        removeLifecycleObservers()

        audioPlayer?.stop()
        audioPlayer = nil

        player?.pause()
        playerLayer?.player = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        playerLooper = nil
        player = nil
    }

    // MARK: - Actions

    @objc private func handlePauseTap() {
        guard !isTornDown, !controlsVisible else { return }
        pausePlayback()
        showControls()
    }

    @objc private func resumeAndHideControls() {
        guard !isTornDown else { return }
        resumePlayback()
        hideControls()
    }

    @objc private func exitTapped() {
        tearDownMedia()
        dismiss(animated: true)
    }

    private func showControls() {
        controlsVisible = true
        pauseTapRecognizer.isEnabled = false
        resumeBackgroundControl.isHidden = false
        playButton.isHidden = false
        exitButton.isHidden = false
        view.bringSubviewToFront(resumeBackgroundControl)
        view.bringSubviewToFront(playButton)
        view.bringSubviewToFront(exitButton)
    }

    private func hideControls() {
        controlsVisible = false
        pauseTapRecognizer.isEnabled = true
        resumeBackgroundControl.isHidden = true
        playButton.isHidden = true
        exitButton.isHidden = true
    }
}
