//
//  HyPopupViewController.swift
//  surveySDK
//
//  Created by Winston on 2023/6/24.
//

import Foundation
import UIKit


///**
//  问卷弹窗
// */
public class HYPopupDialog: UIViewController {
    var survey : Optional<HYUISurveyView>;
    var config: Optional<Dictionary<String, Any>>;
    var _constraint: NSLayoutConstraint? = nil;
    var _previousHeight: CGFloat = CGFloat(0);
    var _previousY: CGFloat = CGFloat(0);
    var _keyboardOpen: Bool = false;
    var options : Dictionary<String, Any>?;
    var surveyJson : Dictionary<String, Any>?;
    var channelConfig : Dictionary<String, Any>?;
    var clientId : String?;
    var animation: Bool = true;
    var animationDuration: Double = 0.5;
    var onLoadCallback: Optional<(_ config: Dictionary<String, Any>) -> Void> = nil;
    var onCloseCallback: Optional<() -> Void> = nil;

    static var lastInstance: HYPopupDialog? = nil;
    static var observation: NSKeyValueObservation?
    static var parentViewController: UIViewController?
    
    static weak var _context: UIViewController? = nil;
    static var _close: Bool = false;

    override public func viewDidLoad() {
        super.viewDidLoad()
        
        
        let clickDismiss = self.options?.index(forKey: "clickDismiss") != nil ? self.options?["clickDismiss"] as! Bool : false
        if (clickDismiss) {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleClick(_:)))
            self.view.addGestureRecognizer(tapGesture)
        }
        
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)

    }
    
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardFrame = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            if !self._keyboardOpen {
                self._previousY = self.survey!.frame.origin.y
                let keyboardHeight = keyboardFrame.cgRectValue.height
                // 获取安全区的顶部和底部插入高度
                let safeAreaTop = view.safeAreaInsets.top
                
                
                // 计算顶部底部剩余当前剩余高度
                let topLeft = max(self.survey!.frame.origin.y - safeAreaTop, 0)
                
                // 可以上抬高度
                // 如果顶部空间足够放下键盘就全部上抬，否则上抬最低高度
                let raiseY = min(topLeft, keyboardHeight);
//                let raiseY = CGFloat(150);
                
                NSLog("raise \(raiseY)");
                
                // 设置视图的新的 y 坐标
                self.survey!.frame.origin.y -= raiseY
                self.survey!.webView.scrollView.isScrollEnabled = false;
                self._keyboardOpen = true
            }
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        // Reset your view's Y position back to 0
        if self._keyboardOpen {
            self.survey!.frame.origin.y = self._previousY
            self._keyboardOpen = false
            if (_previousHeight != 0) {
                _constraint!.constant = _previousHeight
            }
            self.survey!.webView.scrollView.isScrollEnabled = true;
        }
    }

    
    static func setupObservation(for parent: UIViewController) {
        HYPopupDialog.parentViewController = parent
        // 开始观察
        HYPopupDialog.observation = parent.observe(\.view.window, options: [.new]) { _, change in
            if change.newValue == nil {
                print("Parent view controller is no longer in the window")
            }
        }
    }
    
    @objc func handleClick(_ sender: UITapGestureRecognizer) {
        NSLog("dismiss survey")
        self.dismissView()
    }
    
    static func checkContextStatus() -> Bool {
        if let context = HYPopupDialog._context, context.isViewLoaded && context.view.window != nil {
            return true
        }
        NSLog("context already dismissed, will skip the popup")
        return false
    }

    
    @objc public static func makeDialog(context: UIViewController, surveyId: String, channelId: String, parameters: Dictionary<String, Any>, options: Dictionary<String, Any>,
                                         onSubmit: Optional<() -> Void> = nil,
                                         onCancel: Optional<() -> Void> = nil,
                                         onError: Optional<(_: String) -> Void> = nil
    ) -> Void {
        makeDialog(context: context, surveyId: surveyId, channelId: channelId, parameters: parameters, options: options, onSubmit: onSubmit, onCancel: onCancel, onError: onError, onLoad: nil)
    }
    
    @objc public static func makeDialog(context: UIViewController, surveyId: String, channelId: String, parameters: Dictionary<String, Any>, options: Dictionary<String, Any>,
                                         onSubmit: Optional<() -> Void> = nil,
                                         onCancel: Optional<() -> Void> = nil,
                                         onError: Optional<(_: String) -> Void> = nil,
                                         onClose: Optional<() -> Void> = nil
    ) -> Void {
        makeDialog(context: context, surveyId: surveyId, channelId: channelId, parameters: parameters, options: options, onSubmit: onSubmit, onCancel: onCancel, onError: onError, onLoad: nil, onClose: onClose)
    }
    
    /**
            主动关闭弹窗
     */
    @objc public static func close() -> Void {
        NSLog("close survey dialog")
        HYPopupDialog._close = true;
        if (HYPopupDialog.lastInstance != nil) {
            HYPopupDialog.lastInstance?.dismissView()
            HYPopupDialog.lastInstance = nil;
        }
    }
    
    /**
        构建popupview
     */
    @objc public static func makeDialog(context: UIViewController, surveyId: String, channelId: String, parameters: Dictionary<String, Any>, options: Dictionary<String, Any>,
                                         onSubmit: Optional<() -> Void> = nil,
                                         onCancel: Optional<() -> Void> = nil,
                                         onError: Optional<(_: String) -> Void> = nil,
                                         onLoad: Optional<(_ config: Dictionary<String, Any>) -> Void> = nil,
                                         onClose: Optional<() -> Void> = nil
                                         ) -> Void {
        
        return internalMakeDialog(context: context, sendId: nil, surveyId: surveyId, channelId: channelId, parameters: parameters, options: options,
                                  onSubmit: onSubmit,
                                  onCancel: onCancel,
                                  onError: onError,
                                  onLoad: onLoad,
                                  onClose: onClose
        )
    }
    
    
    /**
        构建popupview
     */
    @objc public static func makeDialogBySendId(context: UIViewController, sendId: String, parameters: Dictionary<String, Any>, options: Dictionary<String, Any>,
                                         onSubmit: Optional<() -> Void> = nil,
                                         onCancel: Optional<() -> Void> = nil,
                                         onError: Optional<(_: String) -> Void> = nil
                                         ) -> Void {
        
        HYPopupDialog._context = context;
        HYPopupDialog._close = false;

        var mOptions : Dictionary<String, Any> = options;
        mOptions.updateValue(true, forKey: "isDialogMode")
        mOptions.updateValue("dialog", forKey: "showType")
        
        return internalMakeDialog(context: context, sendId: sendId, surveyId: nil, channelId: nil, parameters: parameters, options: options,
                                  onSubmit: onSubmit,
                                  onCancel: onCancel,
                                  onError: onError,
                                  onLoad: nil,
                                  onClose: nil
        )
    }
    
    /**
        构建popupview
     */
    @objc public static func makeDialogBySendId(context: UIViewController, sendId: String, parameters: Dictionary<String, Any>, options: Dictionary<String, Any>,
                                         onSubmit: Optional<() -> Void> = nil,
                                         onCancel: Optional<() -> Void> = nil,
                                         onError: Optional<(_: String) -> Void> = nil,
                                         onClose: Optional<() -> Void> = nil
                                         ) -> Void {
        
        HYPopupDialog._context = context;
        HYPopupDialog._close = false;

        var mOptions : Dictionary<String, Any> = options;
        mOptions.updateValue(true, forKey: "isDialogMode")
        mOptions.updateValue("dialog", forKey: "showType")
        
        return internalMakeDialog(context: context, sendId: sendId, surveyId: nil, channelId: nil, parameters: parameters, options: options,
                                  onSubmit: onSubmit,
                                  onCancel: onCancel,
                                  onError: onError,
                                  onLoad: nil,
                                  onClose: onClose
        )
    }
    
    /**
      内部dialog逻辑
     */
    private static func internalMakeDialog(context: UIViewController, sendId: String?, surveyId: String?, channelId: String?, parameters: Dictionary<String, Any>, options: Dictionary<String, Any>,
                                         onSubmit: Optional<() -> Void> = nil,
                                         onCancel: Optional<() -> Void> = nil,
                                         onError: Optional<(_: String) -> Void> = nil,
                                         onLoad: Optional<(_ config: Dictionary<String, Any>) -> Void> = nil,
                                         onClose: Optional<() -> Void> = nil
                                         ) -> Void {
        
        if (!HYGlobalConfig.check()) {
            NSLog("surveySDK->global access code is not ready or invalid");
            if (onError != nil) {
                onError!("global access code is not ready or invalid");
            }
            return;
        }

        HYPopupDialog._context = context;
        HYPopupDialog._close = false;
        let server = options.index(forKey: "server") != nil ? options["server"] as! String : HYGlobalConfig.server
        let showDelay = options.index(forKey: "showDelay") != nil ? options["showDelay"] as! Int : 0

        var mOptions : Dictionary<String, Any> = options;
        mOptions.updateValue(true, forKey: "isDialogMode")
        mOptions.updateValue("dialog", forKey: "showType")
        
        HYSurveyService.unionStart(server: server, sendId: sendId, surveyId: surveyId, channelId: channelId, parameters: parameters, onCallback: { sr, error in
            
            if (sr != nil && error == nil) {
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(showDelay)) {
                    let canPop = HYPopupDialog.checkContextStatus()
                    if (!canPop || HYPopupDialog._close) {
                        NSLog("surveySDK->skip the popup");
                        if (onError != nil) {
                            onError!("context is not visible, popup skip!");
                        }
                        return;
                    }
                    HYPopupDialog.lastInstance = HYPopupDialog(surveyId: sr!.sid, channelId: sr!.cid, surveyJson: sr!.raw, channelConfig: sr!.channelConfig,  clientId: sr?.clientId, parameters: parameters, options: mOptions, config: sr!.channelConfig, onSubmit: onSubmit, onCancel: onCancel, onLoad: onLoad, onClose: onClose, onError: { errorMsg in
                            NSLog("surveySDK->Dialog error: %@", errorMsg);
                            close();
                            if (onError != nil) {
                                onError!(errorMsg);
                            }
                    });
                    NSLog("surveySDK->makeDialog will show up! clientId: %@", sr!.clientId)
                    
                    HYPopupDialog.lastInstance!.modalPresentationStyle = .overFullScreen
                    context.present(HYPopupDialog.lastInstance!, animated: true) {
                        NSLog("surveySDK->Modal present!")
                    }
                }

            } else {
                if (onError != nil) {
                    onError!(error ?? "问卷暂停访问")
                }
            }
        });
    }

    
    

    /**
     初始化view
     */
    private init(surveyId: String, channelId: String, surveyJson: Optional<Dictionary<String, Any>> = nil, channelConfig: Optional<Dictionary<String, Any>> = nil,  clientId: String?, parameters: Dictionary<String, Any>, options: Dictionary<String, Any>,
               config: Dictionary<String, Any>,
            onSubmit: Optional<() -> Void> = nil,
            onCancel: Optional<() -> Void> = nil,
            onLoad: Optional<(_ config: Dictionary<String, Any>) -> Void> = nil,
            onClose: Optional<() -> Void> = nil,
            onError: Optional<(String) -> Void> = nil
    ) {
        self.surveyJson = surveyJson;
        self.clientId = clientId;
        self.options = options;
        self.config = config;
        self.channelConfig = channelConfig;
        self.onLoadCallback = onLoad;
        self.onCloseCallback = onClose;

        survey = HYUISurveyView.makeSurveyControllerEx(surveyId: surveyId, channelId: channelId, surveyJson: self.surveyJson, channelConfig: channelConfig,  clientId: self.clientId,  parameters: parameters, options: options,
                                                       onSubmit:  onSubmit, onCancel: onCancel, onError: onError)
        
        super.init(nibName: nil, bundle: nil);
        
        survey?.setOnSize(callback: self.onSize);
        survey?.setOnClose(callback: self.onClose);
        survey?.setOnLoad(callback: self.onLoad);

        self.animation = options.index(forKey: "animation") != nil ? options["animation"] as! Bool : false
        self.animationDuration = options.index(forKey: "animationDuration") != nil ? options["animationDuration"] as! Double : 0.5
        
        let embedHeightMode: String = Util.optString(config: config, key: "embedHeightMode", fallback: "AUTO")
        let embedHeight: Int = Util.parsePx(value: config["embedHeight"] as! String, max: Int(view.frame.height));
        let embedVerticalAlign = Util.optString(config: config, key: "embedVerticalAlign", fallback: "CENTER");

        survey!.translatesAutoresizingMaskIntoConstraints = false
        modalTransitionStyle = .crossDissolve;
        
        view.addSubview(survey!)
        
        view.bringSubview(toFront: survey!)
        
        if (embedVerticalAlign == "CENTER") {
            NSLayoutConstraint.activate([
                survey!.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                survey!.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                survey!.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: CGFloat(0)),
                survey!.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -CGFloat(0))
            ])
        } else if (embedVerticalAlign == "TOP") {
            NSLayoutConstraint.activate([
                survey!.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                survey!.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0), // 使用安全区域的顶部锚点
                survey!.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: CGFloat(0)),
                survey!.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -CGFloat(0))
            ])
        } else {
            // bottom or default
            NSLayoutConstraint.activate([
                survey!.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                survey!.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
                survey!.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: CGFloat(0)),
                survey!.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -CGFloat(0))
            ])
        }

        if (self._constraint != nil) {
            self._constraint?.isActive = false
        }
        if (embedHeightMode == "FIX") {
            self._constraint = survey!.heightAnchor.constraint(equalToConstant: CGFloat(embedHeight));
        } else {
            // AUTO or default
            let initHeight = options.index(forKey: "height") != nil ? options["height"] as! Int : 1
            self._constraint = survey!.heightAnchor.constraint(equalToConstant: CGFloat(initHeight));
        }
        self._constraint?.priority = UILayoutPriority(1000)
        self._constraint?.isActive = true;
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /**
        响应onSize
     */
    func onSize(height: Int) {
        if (self._keyboardOpen) {
            return
        }
        let embedHeightMode = Util.optString(config: config!, key: "embedHeightMode", fallback: "AUTO");

        if (embedHeightMode != "FIX" && _constraint != nil) {
            let embedHeight: Int = Util.parsePx(value: config!["embedHeight"] as! String, max: Int(view.frame.height));
            _constraint?.constant = CGFloat(min(embedHeight, height));
        }
        
        view.layoutIfNeeded()
        
        if (animation) {
            UIView.animate(withDuration: animationDuration, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
    
    /**
        响应onError
     */
    func onError(config: Dictionary<String, Any>) {
        self.dismissView();
    }
    
    /**
        响应Load
     */
    func onLoad(config: Dictionary<String, Any>) {
//        NSLog("popupDialog->onLoad")
        let embedBackGround = Util.optBool(config: config, key: "embedBackGround", fallback: true);
        if (embedBackGround) {
            self.view.layer.backgroundColor = UIColor.black.withAlphaComponent(0.6).cgColor;
        }
        if self.onLoadCallback != nil {
            self.onLoadCallback!(config);
        }
    }
    
    /**
        响应Close
     */
    func onClose() {
        self.dismissView();
        if self.onCloseCallback != nil {
            self.onCloseCallback!();
        }
    }
    
    deinit {
        // 释放 KVO 观察者
        HYPopupDialog.observation?.invalidate()
        HYPopupDialog.observation = nil
        
        // 额外的安全释放，防止资源遗漏（可选）
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    /**
        popup消失
     */
    @objc func dismissView() {
        NSLog("dismiss popup")
        self.dismiss(animated: animation, completion: {
            HYPopupDialog._close = false // 重置关闭状态
        })
        HYPopupDialog.lastInstance = nil
    }
    

}


