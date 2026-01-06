//
//  VixenBaseModule.swift
//  VixenAI
//
//  所有视图模块的基类
//

import SwiftUI
import UIKit

// MARK: - SwiftUI 基础视图协议
protocol VixenBaseModuleProtocol: View {
    associatedtype Content: View
    var body: Content { get }
}

// MARK: - UIKit 基础视图控制器
class VixenBaseModule: UIViewController {
    
    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        bindData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        moduleWillAppear()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        moduleDidAppear()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        moduleWillDisappear()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        moduleDidDisappear()
    }
    
    // MARK: - 子类重写方法
    
    /// 设置 UI
    func setupUI() {
        view.backgroundColor = UIColor(VixenColorConfig.backgroundColor)
    }
    
    /// 设置约束
    func setupConstraints() {
        // 子类重写
    }
    
    /// 绑定数据
    func bindData() {
        // 子类重写
    }
    
    /// 视图即将显示
    func moduleWillAppear() {
        // 子类重写
    }
    
    /// 视图已经显示
    func moduleDidAppear() {
        // 子类重写
    }
    
    /// 视图即将消失
    func moduleWillDisappear() {
        // 子类重写
    }
    
    /// 视图已经消失
    func moduleDidDisappear() {
        // 子类重写
    }
    
    // MARK: - 工具方法
    
    /// 显示加载提示
    func showLoading(message: String = "加载中...") {
        // TODO: 实现加载提示
    }
    
    /// 隐藏加载提示
    func hideLoading() {
        // TODO: 实现隐藏加载
    }
    
    /// 显示提示信息
    func showToast(message: String) {
        // TODO: 实现 Toast 提示
    }
    
    /// 显示错误信息
    func showError(message: String) {
        showToast(message: message)
    }
}

// MARK: - UIColor Extension
extension UIColor {
    convenience init(_ color: Color) {
        let components = color.components()
        self.init(red: components.r, green: components.g, blue: components.b, alpha: components.a)
    }
}

extension Color {
    func components() -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        let uiColor = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b, a)
    }
}

