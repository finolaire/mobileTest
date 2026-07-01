//
//  EyesOverlayViewController.swift
//  EnglishSentence
//
//  全屏 GIF（SDWebImage SDAnimatedImageView）+ 本地 m4a；点屏暂停并显示 SF 符号按钮；
//  点按钮外区域或「继续」恢复播放并隐藏按钮；「退出」关闭。
//

import AVFoundation
import SDWebImage
import SnapKit
import UIKit

final class EyesOverlayViewController: UIViewController {

    private let animatedImageView: SDAnimatedImageView = {
        let v = SDAnimatedImageView()
        v.contentMode = .scaleAspectFill
        v.clipsToBounds = true
        v.backgroundColor = .black
        return v
    }()

    /// 控制条未显示时：整屏点击 → 暂停
    private let pauseTapRecognizer = UITapGestureRecognizer()

    /// 控制条显示时：铺满底层，点击 → 继续播放并隐藏按钮（按钮在上层接收独立点击）
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

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        view.addSubview(animatedImageView)
        view.addSubview(resumeBackgroundControl)
        view.addSubview(playButton)
        view.addSubview(exitButton)

        animatedImageView.snp.makeConstraints { $0.edges.equalToSuperview() }
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

        loadGIF()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playAudioIfPossible()
        animatedImageView.startAnimating()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        audioPlayer?.stop()
        animatedImageView.stopAnimating()
    }

    private func resourceURL(name: String, ext: String) -> URL? {
        if let u = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Resource") { return u }
        return Bundle.main.url(forResource: name, withExtension: ext)
    }

    private func loadGIF() {
        guard let url = resourceURL(name: "eyes_animation", ext: "gif") else { return }
        guard let data = try? Data(contentsOf: url), let animated = SDAnimatedImage(data: data) else { return }
        animatedImageView.image = animated
    }

    private func playAudioIfPossible() {
        guard let url = resourceURL(name: "eyes_audio", ext: "m4a") else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            audioPlayer = nil
        }
    }

    @objc private func handlePauseTap() {
        guard !controlsVisible else { return }
        pausePlayback()
        showControls()
    }

    @objc private func resumeAndHideControls() {
        resumePlayback()
        hideControls()
    }

    @objc private func exitTapped() {
        audioPlayer?.stop()
        animatedImageView.stopAnimating()
        dismiss(animated: true)
    }

    private func pausePlayback() {
        audioPlayer?.pause()
        animatedImageView.stopAnimating()
    }

    private func resumePlayback() {
        audioPlayer?.play()
        animatedImageView.startAnimating()
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
