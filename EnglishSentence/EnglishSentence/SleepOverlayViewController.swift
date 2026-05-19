//
//  SleepOverlayViewController.swift
//  EnglishSentence
//
//  全屏黑底 + 居中偏上 GIF（宽 200，等比）+ sleep_audio.mp3；
//  交互与 EyesOverlayViewController 一致。
//

import AVFoundation
import SDWebImage
import SnapKit
import UIKit

// MARK: - 代码绘制的呼吸闪烁图案

private enum TwinkleShapeKind: CaseIterable {
    case ringedPlanet
    case pentagram
    case fourPointStar
    case stellarBurst
}

private enum TwinkleShapeFactory {
    static func path(for kind: TwinkleShapeKind, in rect: CGRect) -> UIBezierPath {
        switch kind {
        case .ringedPlanet:
            return ringedPlanetPath(in: rect)
        case .pentagram:
            return starPath(in: rect, points: 5, innerRadiusRatio: 0.42, irregularity: 0.08)
        case .fourPointStar:
            return starPath(in: rect, points: 4, innerRadiusRatio: 0.22, irregularity: 0.12)
        case .stellarBurst:
            return stellarBurstPath(in: rect)
        }
    }

    /// 带星环的星球（土星造型）：倾斜椭圆环 + 中央球体
    private static func ringedPlanetPath(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let base = min(rect.width, rect.height)
        let planetR = base * 0.22
        let tilt = CGFloat(-20 * Double.pi / 180)

        func ellipsePath(center c: CGPoint, rx: CGFloat, ry: CGFloat) -> UIBezierPath {
            let e = UIBezierPath(ovalIn: CGRect(x: c.x - rx, y: c.y - ry, width: rx * 2, height: ry * 2))
            var t = CGAffineTransform(translationX: c.x, y: c.y)
            t = t.rotated(by: tilt)
            t = t.translatedBy(x: -c.x, y: -c.y)
            e.apply(t)
            return e
        }

        // 星环比原先收小一圈，更贴近球体
        let ringRx = base * 0.32
        let ringRy = ringRx * 0.24

        let ringBand = UIBezierPath()
        ringBand.append(ellipsePath(center: center, rx: ringRx, ry: ringRy))
        ringBand.append(ellipsePath(center: center, rx: ringRx * 0.72, ry: ringRy * 0.72))
        ringBand.usesEvenOddFillRule = true
        path.append(ringBand)

        path.append(UIBezierPath(ovalIn: CGRect(
            x: center.x - planetR,
            y: center.y - planetR,
            width: planetR * 2,
            height: planetR * 2
        )))

        return path
    }

    /// 多角星；`irregularity` 让外圈半径略有起伏，看起来更「不规则」
    private static func starPath(
        in rect: CGRect,
        points: Int,
        innerRadiusRatio: CGFloat,
        irregularity: CGFloat
    ) -> UIBezierPath {
        let path = UIBezierPath()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerBase = min(rect.width, rect.height) * 0.48
        let innerBase = outerBase * innerRadiusRatio
        let total = points * 2
        var radii: [CGFloat] = []
        for i in 0..<total {
            let isOuter = i.isMultiple(of: 2)
            let base = isOuter ? outerBase : innerBase
            let jitter = 1 + CGFloat.random(in: -irregularity...irregularity)
            radii.append(base * jitter)
        }
        for i in 0..<total {
            let angle = (CGFloat(i) / CGFloat(total)) * (.pi * 2) - .pi / 2
            let p = CGPoint(
                x: center.x + cos(angle) * radii[i],
                y: center.y + sin(angle) * radii[i]
            )
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.close()
        return path
    }

    /// 恒星：小圆核 + 长短不一的光芒
    private static func stellarBurstPath(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let coreR = min(rect.width, rect.height) * 0.14
        path.append(UIBezierPath(ovalIn: CGRect(
            x: center.x - coreR,
            y: center.y - coreR,
            width: coreR * 2,
            height: coreR * 2
        )))
        let rayCount = 8
        for i in 0..<rayCount {
            let angle = (CGFloat(i) / CGFloat(rayCount)) * (.pi * 2) + CGFloat.random(in: -0.08...0.08)
            let len = min(rect.width, rect.height) * CGFloat.random(in: 0.38...0.5)
            let w = CGFloat.random(in: 0.06...0.11) * min(rect.width, rect.height)
            let tip = CGPoint(x: center.x + cos(angle) * len, y: center.y + sin(angle) * len)
            let side = angle + .pi / 2
            let baseL = CGPoint(
                x: center.x + cos(side) * w + cos(angle) * coreR * 0.6,
                y: center.y + sin(side) * w + sin(angle) * coreR * 0.6
            )
            let baseR = CGPoint(
                x: center.x - cos(side) * w + cos(angle) * coreR * 0.6,
                y: center.y - sin(side) * w + sin(angle) * coreR * 0.6
            )
            let tri = UIBezierPath()
            tri.move(to: tip)
            tri.addLine(to: baseL)
            tri.addLine(to: baseR)
            tri.close()
            path.append(tri)
        }
        return path
    }
}

private struct TwinkleGradientColors {
    let highlight: UIColor
    let mid: UIColor
    let deep: UIColor
    let glow: UIColor

    static func make(from base: UIColor) -> TwinkleGradientColors {
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        if base.getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            return TwinkleGradientColors(
                highlight: UIColor(hue: h, saturation: s * 0.75, brightness: min(b * 1.28, 1), alpha: a),
                mid: base,
                deep: UIColor(hue: h, saturation: min(s * 1.15, 1), brightness: b * 0.42, alpha: a * 0.95),
                glow: base.withAlphaComponent(0.55)
            )
        }
        var r: CGFloat = 0
        var g: CGFloat = 0
        var bl: CGFloat = 0
        base.getRed(&r, green: &g, blue: &bl, alpha: &a)
        return TwinkleGradientColors(
            highlight: UIColor(red: min(r * 1.25, 1), green: min(g * 1.25, 1), blue: min(bl * 1.25, 1), alpha: a),
            mid: base,
            deep: UIColor(red: r * 0.45, green: g * 0.45, blue: bl * 0.45, alpha: a * 0.95),
            glow: base.withAlphaComponent(0.55)
        )
    }
}

private final class TwinkleParticleView: UIView {
    private let kind: TwinkleShapeKind
    private let gradient: TwinkleGradientColors
    private let baseAngle: CGFloat
    private let shapeSide: CGFloat

    /// `shapeSide`：图案本体边长 30～100；视图略大以容纳晕光
    init(kind: TwinkleShapeKind, color: UIColor, shapeSide: CGFloat, angle: CGFloat) {
        self.kind = kind
        self.gradient = TwinkleGradientColors.make(from: color)
        self.baseAngle = angle
        self.shapeSide = shapeSide
        let glowPad = shapeSide * 0.42
        let total = shapeSide + glowPad * 2
        super.init(frame: CGRect(x: 0, y: 0, width: total, height: total))
        backgroundColor = .clear
        isOpaque = false
        clipsToBounds = false
        layer.masksToBounds = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        let pad = (min(rect.width, rect.height) - shapeSide) / 2
        let shapeRect = rect.insetBy(dx: pad, dy: pad)
        let path = TwinkleShapeFactory.path(for: kind, in: shapeRect)
        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        // 外层晕光
        ctx.saveGState()
        ctx.setShadow(offset: .zero, blur: shapeSide * 0.38, color: gradient.glow.cgColor)
        gradient.glow.withAlphaComponent(0.28).setFill()
        path.fill()
        ctx.restoreGState()

        // 中层柔光
        ctx.saveGState()
        ctx.setShadow(offset: .zero, blur: shapeSide * 0.16, color: gradient.mid.withAlphaComponent(0.85).cgColor)
        gradient.mid.withAlphaComponent(0.22).setFill()
        path.fill()
        ctx.restoreGState()

        // 径向渐变 + 偏上高光（光影）
        ctx.saveGState()
        path.addClip()
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let cgColors = [gradient.highlight.cgColor, gradient.mid.cgColor, gradient.deep.cgColor] as CFArray
        let locations: [CGFloat] = [0, 0.38, 1]
        guard let radial = CGGradient(colorsSpace: colorSpace, colors: cgColors, locations: locations) else {
            ctx.restoreGState()
            return
        }
        let lightCenter = CGPoint(
            x: shapeRect.midX - shapeRect.width * 0.2,
            y: shapeRect.midY - shapeRect.height * 0.24
        )
        let bodyCenter = CGPoint(x: shapeRect.midX, y: shapeRect.midY)
        let radius = max(shapeRect.width, shapeRect.height) * 0.58
        ctx.drawRadialGradient(
            radial,
            startCenter: lightCenter,
            startRadius: 0,
            endCenter: bodyCenter,
            endRadius: radius,
            options: [.drawsAfterEndLocation]
        )
        ctx.restoreGState()

        // 轻微高光条（增强立体感）
        ctx.saveGState()
        path.addClip()
        let glossColors = [
            UIColor.white.withAlphaComponent(0.42).cgColor,
            UIColor.white.withAlphaComponent(0).cgColor,
        ] as CFArray
        if let gloss = CGGradient(colorsSpace: colorSpace, colors: glossColors, locations: [0, 1]) {
            let glossStart = CGPoint(x: shapeRect.minX, y: shapeRect.minY)
            let glossEnd = CGPoint(x: shapeRect.midX, y: shapeRect.midY)
            ctx.drawLinearGradient(gloss, start: glossStart, end: glossEnd, options: [])
        }
        ctx.restoreGState()
    }
}

private final class SleepTwinkleStarsView: UIView {

    private let palette: [UIColor] = [
        UIColor(red: 1.0, green: 0.88, blue: 0.45, alpha: 1),
        UIColor(red: 0.72, green: 0.88, blue: 1.0, alpha: 1),
        UIColor(red: 1.0, green: 0.62, blue: 0.78, alpha: 1),
        UIColor(red: 0.82, green: 1.0, blue: 0.78, alpha: 1),
        UIColor(red: 0.78, green: 0.72, blue: 1.0, alpha: 1),
        UIColor.white.withAlphaComponent(0.9),
    ]

    private var spawnTimer: Timer?
    private var isPaused = false
    private let maxConcurrent = 3

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func start() {
        stop()
        isPaused = false
        spawnWave()
        scheduleNextWave(after: TimeInterval.random(in: 3.2...5.5))
    }

    func stop() {
        spawnTimer?.invalidate()
        spawnTimer = nil
        clearParticles()
    }

    func pause() {
        isPaused = true
        spawnTimer?.invalidate()
        spawnTimer = nil
        clearParticles()
    }

    func resume() {
        guard isPaused else { return }
        isPaused = false
        spawnWave()
        scheduleNextWave(after: TimeInterval.random(in: 3.2...5.5))
    }

    private func clearParticles() {
        subviews.forEach { $0.layer.removeAllAnimations(); $0.removeFromSuperview() }
    }

    private func scheduleNextWave(after interval: TimeInterval) {
        spawnTimer?.invalidate()
        spawnTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            guard let self, !self.isPaused else { return }
            self.spawnWave()
            self.scheduleNextWave(after: TimeInterval.random(in: 3.2...5.5))
        }
        RunLoop.main.add(spawnTimer!, forMode: .common)
    }

    /// 每一波随机 1～3 个（且不超过当前空余名额），不会铺太满
    private func spawnWave() {
        guard !isPaused, bounds.width > 40, bounds.height > 40 else { return }
        let active = subviews.count
        guard active < maxConcurrent else { return }
        let slots = maxConcurrent - active
        let count = Int.random(in: 1...min(maxConcurrent, slots))
        for i in 0..<count {
            let delay = Double(i) * Double.random(in: 0.4...0.9)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.spawnOneParticle()
            }
        }
    }

    private func spawnOneParticle() {
        guard !isPaused, subviews.count < maxConcurrent else { return }

        let kind = TwinkleShapeKind.allCases.randomElement() ?? .pentagram
        let color = palette.randomElement() ?? .white
        let shapeSide = CGFloat.random(in: 30...100)
        let angle = CGFloat.random(in: 0...(2 * .pi))

        let particle = TwinkleParticleView(kind: kind, color: color, shapeSide: shapeSide, angle: angle)
        particle.alpha = 0.06

        let inset: CGFloat = 36
        let w = bounds.width - inset * 2
        let h = bounds.height - inset * 2
        let x = inset + CGFloat.random(in: 0...max(w, 1))
        let y = inset + CGFloat.random(in: 0...max(h, 1))
        particle.center = CGPoint(x: x, y: y)
        addSubview(particle)

        runBreathingAnimation(on: particle, baseAngle: angle)
    }

    private func runBreathingAnimation(on particle: TwinkleParticleView, baseAngle: CGFloat) {
        let duration = TimeInterval.random(in: 2.8...5.2)
        let peakAlpha = CGFloat.random(in: 0.7...0.98)
        let peakScale = CGFloat.random(in: 0.92...1.1)
        // 呼吸缩放：不把 30pt 缩到过小，仅在 0.82～1.05 之间起伏
        let t0 = CGAffineTransform(scaleX: 0.82, y: 0.82).rotated(by: baseAngle)
        let t1 = CGAffineTransform(scaleX: peakScale, y: peakScale).rotated(by: baseAngle)
        let t2 = CGAffineTransform(scaleX: 0.78, y: 0.78).rotated(by: baseAngle)
        particle.transform = t0

        UIView.animate(
            withDuration: duration * 0.52,
            delay: TimeInterval.random(in: 0...0.5),
            options: [.curveEaseInOut, .allowUserInteraction, .beginFromCurrentState]
        ) {
            particle.alpha = peakAlpha
            particle.transform = t1
        } completion: { [weak particle] _ in
            guard let particle, particle.superview != nil, !self.isPaused else {
                particle?.removeFromSuperview()
                return
            }
            UIView.animate(
                withDuration: duration * 0.48,
                delay: 0,
                options: [.curveEaseInOut, .allowUserInteraction, .beginFromCurrentState]
            ) {
                particle.alpha = 0.05
                particle.transform = t2
            } completion: { _ in
                particle.removeFromSuperview()
            }
        }
    }
}

final class SleepOverlayViewController: UIViewController {

    private let twinkleStarsView = SleepTwinkleStarsView()

    private let animatedImageView: SDAnimatedImageView = {
        let v = SDAnimatedImageView()
        v.contentMode = .scaleAspectFit
        v.clipsToBounds = true
        v.backgroundColor = .clear
        return v
    }()

    private let pauseTapRecognizer = UITapGestureRecognizer()

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

        view.addSubview(twinkleStarsView)
        view.addSubview(animatedImageView)
        view.addSubview(resumeBackgroundControl)
        view.addSubview(playButton)
        view.addSubview(exitButton)

        twinkleStarsView.snp.makeConstraints { $0.edges.equalToSuperview() }
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
        twinkleStarsView.start()
        playAudioIfPossible()
        animatedImageView.startAnimating()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        twinkleStarsView.stop()
        audioPlayer?.stop()
        animatedImageView.stopAnimating()
    }

    private func resourceURL(name: String, ext: String) -> URL? {
        if let u = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Resource") { return u }
        return Bundle.main.url(forResource: name, withExtension: ext)
    }

    private func loadGIF() {
        guard let url = resourceURL(name: "sleep_animation", ext: "gif") else { return }
        guard let data = try? Data(contentsOf: url), let animated = SDAnimatedImage(data: data) else { return }
        animatedImageView.image = animated
        updateGIFLayout(imageSize: animated.size)
    }

    private func updateGIFLayout(imageSize: CGSize) {
        let width: CGFloat = 300
        let ratio = imageSize.height / max(imageSize.width, 1)

        animatedImageView.snp.remakeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-150)
            make.width.equalTo(width)
            make.height.equalTo(width * ratio)
        }
    }

    private func playAudioIfPossible() {
        guard let url = resourceURL(name: "sleep_audio", ext: "mp3") else { return }
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
        twinkleStarsView.pause()
    }

    private func resumePlayback() {
        audioPlayer?.play()
        animatedImageView.startAnimating()
        twinkleStarsView.resume()
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
