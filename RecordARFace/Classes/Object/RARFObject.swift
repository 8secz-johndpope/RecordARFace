//
//  RARFObject.swift
//  RecordARFace
//
//  Created by 永田大祐 on 2019/01/06.
//

import ARKit
import UIKit
import WebKit

public var RASRFWebUrlPath = String()

@available(iOS 11.0, *)
protocol ARSCNDelegate: ARSCNViewDelegate {
    var resource: UIColor { get set }
    var contentNode: SCNNode? { get set }
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode?
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor)
}


@available(iOS 11.0, *)
final class RARFObject: NSObject, ARSessionDelegate, WKNavigationDelegate {

    public var indexNumber = 0
    public var contentOffSetY: CGFloat = 0

    var y: CGFloat = 0
    var webFlg = false
    var tableFlg = false

    var timer: Timer?
    var numTimer: Timer?
    var spellTimer: Timer?
    var anchors: ARAnchor?
    var vc = UIViewController()
    var rARFWebUIView: RARFWebUIView!
    var spellKey: RARFSpellAndKeyBoard?
    var luangageKey: RARFLuangageKeyBoard!
    var numberKey = RARFNumberKeyboardView()
    var numberChangeView: RARFNumberChangeKeyBoardView?

    lazy var webView: WKWebView = {
        var webView = WKWebView()
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height), configuration: webConfiguration)
        webView.navigationDelegate = self
        webView.scrollView.delegate = self
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }()

    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.frame = UIScreen.main.bounds
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "RARFCell")
        return tableView
    }()

    lazy var arscnView: ARSCNView = {
        let arscnView = ARSCNView()
        arscnView.delegate = self
        arscnView.session.delegate = self
        arscnView.automaticallyUpdatesLighting = true
        return arscnView
    }()

    lazy var eView: UIView = {
        let eView = UIView()
        eView.frame = CGRect(x: 0,y: 0 ,width: 25, height: 25)
        eView.layer.cornerRadius = eView.frame.height/2
        return eView
    }()

    private var screenNode: SCNNode = {
        let screenNode = SCNPlane(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        screenNode.firstMaterial?.isDoubleSided = true
        return SCNNode(geometry: screenNode)
    }()

    private var nodeFace = SCNNode()
    private var phoneNode = SCNNode()
    private var eyeData: RARFEyeData?
    private var texturedFace: RARFTexturedFace?


    override init() {
        super.init()

        rARFWebUIView = RARFWebUIView()
        spellKey = RARFSpellAndKeyBoard(ob: self)
        numberChangeView = RARFNumberChangeKeyBoardView(ob: self)
        luangageKey = RARFLuangageKeyBoard(spellKey: spellKey!  ,numberKey: numberChangeView!)
        tableView.addSubview(numberKey)
        tableView.addSubview(spellKey!)
        tableView.addSubview(luangageKey!)
        tableView.addSubview(numberChangeView!)
    }

    func webReload() {
        webFlg = true
        guard let url = URL(string: RASRFWebUrlPath) else { fatalError() }
        let request = URLRequest(url: url)
        webView.load(request)
    }

    func resetTracking() {
        if self.anchors != nil { self.arscnView.session.remove(anchor: self.anchors!) }
        UIApplication.shared.isIdleTimerDisabled = true
        guard ARFaceTrackingConfiguration.isSupported else { return }
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        self.arscnView.session.run(configuration, options: [.resetTracking])
    }

    func texturedFace(color: UIColor) {
        eView.isHidden = true
        texturedFace = RARFTexturedFace(resource: color)
        resetTracking()
    }

    func eyeTracking(color: UIColor, flg: Bool) {
        eView.isHidden = false
        texturedFace = RARFTexturedFace(resource: .clear)
        #if targetEnvironment(simulator)
        #else
        if flg == false {
            numberKey.isHidden = false
            spellKey?.isHidden = true
            luangageKey?.isHidden = true
            numberChangeView?.isHidden = true
            timer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(numberKeyUpdate), userInfo: nil, repeats: true)
        } else {
            numberKey.isHidden = true
            spellKey?.isHidden = false
            luangageKey?.isHidden = false
            numberChangeView?.isHidden = false
            timer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(luangageKeyUpdate), userInfo: nil, repeats: true)
        }

        arscnView.addSubview(tableView)
        tableView.addSubview(eView)
        tableView.isHidden = false
        tableView.delegate = self
        tableView.dataSource = self
        eView = RARFFlameView(eView: eView, color: color).eViews
        eyeData = RARFEyeData()
        arscnView.scene.rootNode.addChildNode(eyeData!)
        arscnView.scene.rootNode.addChildNode(phoneNode)
        phoneNode.geometry?.firstMaterial?.isDoubleSided = true
        phoneNode.addChildNode(screenNode)
        resetTracking()
        #endif
    }

    func eyeTrackDataSet(color: UIColor? = .white) {
        numberKey.isHidden = true
        spellKey?.isHidden = true
        luangageKey?.isHidden = true
        numberChangeView?.isHidden = true
        eView = RARFFlameView(eView: eView, color: color!).eViews
        eyeData = RARFEyeData()
        arscnView.scene.rootNode.addChildNode(eyeData!)
        arscnView.scene.rootNode.addChildNode(phoneNode)
        phoneNode.geometry?.firstMaterial?.isDoubleSided = true
        phoneNode.addChildNode(screenNode)
        resetTracking()
    }

    func eyeTrackingScroll(color: UIColor? = .white) {
        #if targetEnvironment(simulator)
        #else
        tableView.isHidden = false

        arscnView.addSubview(tableView)
        tableView.addSubview(eView)
        tableView.delegate = self
        tableView.dataSource = self
        eyeTrackDataSet(color: color)
        #endif
    }

    func eyeTrackingWebView(color: UIColor? = .white) {
        #if targetEnvironment(simulator)
        #else
        tableView.isHidden = true

        webReload()
        webView.addSubview(rARFWebUIView)
        webView.addSubview(eView)
        eyeTrackDataSet(color: color)
        #endif
    }

    func tableContentOff(tableFlg: Bool) {
        if tableFlg == true {
            let offset = CGPoint(x: 0, y: (-self.eView.frame.origin.y)+self.tableView.frame.height/2)
            self.tableView.setContentOffset(offset, animated: true)
        }
    }

    func webForward() {
        if webFlg == true {
            vc.view.alpha = 0
            webView.goForward()
            let offset = CGPoint(x: 0, y: -(UINavigationController().navigationBar.frame.height + UIApplication.shared.statusBarFrame.height))
            webView.scrollView.setContentOffset(offset, animated: true)
            UIView.animate(withDuration: 0.3) { self.webView.alpha = 1 }
            UIView.animate(withDuration: 0.6) { self.vc.view.alpha = 1 }
        }
    }

    func webBack() {
        if webFlg == true {
            if webView.backForwardList.backList.count == 0 {
                webFlg = false
                webView.alpha = 0
            } else {
                vc.view.alpha = 0
                webView.goBack()
                let offset = CGPoint(x: 0, y: -(UINavigationController().navigationBar.frame.height + UIApplication.shared.statusBarFrame.height))
                webView.scrollView.setContentOffset(offset, animated: true)
                UIView.animate(withDuration: 0.3) { self.webView.alpha = 1 }
                UIView.animate(withDuration: 0.6) { self.vc.view.alpha = 1 }
            }
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(WKNavigationActionPolicy.allow)
        if webFlg == true {
            self.webFlg = false
            self.y = 0
            vc.view.alpha = 0
            let offset = CGPoint(x: 0, y: -(UINavigationController().navigationBar.frame.height + UIApplication.shared.statusBarFrame.height))
            self.webView.scrollView.setContentOffset(offset, animated: false)
            UIView.animate(withDuration: 0.3) { self.webView.alpha = 1 }
            UIView.animate(withDuration: 0.6) { self.vc.view.alpha = 1 }
        }
    }

    @objc func numberKeyUpdate() { numberKey.originTextField(rect: self.eView.frame) }
    
    @objc func luangageKeyUpdate() { luangageKey.originTextField(rect: self.eView.frame, timer: timer!) }
    
    @objc func numBarUpdate() { numberChangeView?.originTextField(rect: self.eView.frame, timer: numTimer!) }
    
    @objc func spellKeyUpdate() { spellKey?.originTextField(rect: self.eView.frame, timer: spellTimer!, view: luangageKey) }

    func updateNumber() { numTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(numBarUpdate), userInfo: nil, repeats: true) }

    func updateSpellKey() { spellTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(spellKeyUpdate), userInfo: nil, repeats: true) }

    func upDateluangageKey() { timer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(luangageKeyUpdate), userInfo: nil, repeats: true) }

    private func webEViewSet() {
        if webFlg == true && eView.frame.origin.y > -0 {
            let offset = CGPoint(x: 0, y: eView.frame.origin.y + self.y)
            webView.scrollView.setContentOffset(offset, animated: true)
            rARFWebUIView.originTextField(rect: eView.frame, rARFObject: self)
        } else {
            let offset = CGPoint(x: 0, y: -(UINavigationController().navigationBar.frame.height + UIApplication.shared.statusBarFrame.height))
            webView.scrollView.setContentOffset(offset, animated: true)
        }
    }

    private func webContentOffSetX() {
        if self.eView.frame.origin.x < 0 {
            webFlg = false
        } else if eView.frame.origin.x > UIScreen.main.bounds.width {
            self.y = webView.scrollView.contentOffset.y
            webFlg = true
        }
    }
}

// MARK: ARSCNViewDelegate
@available(iOS 11.0, *)
extension RARFObject: ARSCNViewDelegate {

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        anchors = anchor
        guard texturedFace?.renderer(renderer, nodeFor: anchor) == nil else {
            guard let contentNode = texturedFace?.renderer(renderer, nodeFor: anchor) else { return }

            nodeFace = contentNode
            node.addChildNode(contentNode)
            return
        }
        guard let contentNode = eyeData?.renderer(renderer, nodeFor: anchor) else { return }
        nodeFace = contentNode
        node.addChildNode(contentNode)
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard texturedFace?.contentNode == nil else {
            texturedFace?.renderer(renderer, didUpdate: nodeFace, for: anchor)
            return
        }
        eyeData?.transform = node.transform
        eyeData?.renderer(renderer, didUpdate: node, for: anchor)
    }

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {

        guard eyeData?.contentNode == nil else {
            if let arscnView = arscnView.pointOfView { phoneNode.transform = arscnView.transform }
            let options : [String: Any] = [SCNHitTestOption.backFaceCulling.rawValue: false,
                                           SCNHitTestOption.searchMode.rawValue: 1,
                                           SCNHitTestOption.ignoreChildNodes.rawValue : false,
                                           SCNHitTestOption.ignoreHiddenNodes.rawValue : false]

            let leftEye = phoneNode.hitTestWithSegment (
                from: phoneNode.convertPosition(eyeData!.leftEye.worldPosition, from: nil),
                to:  phoneNode.convertPosition(eyeData!.leftEyeEnd.worldPosition, from: nil),
                options: options)

            let rightEye = phoneNode.hitTestWithSegment (
                from: phoneNode.convertPosition(eyeData!.rightEye.worldPosition, from: nil),
                to:  phoneNode.convertPosition(eyeData!.rightEyeEnd.worldPosition, from: nil),
                options: options)

            if !leftEye.isEmpty && !rightEye.isEmpty {
                guard let coords = eyeData?.eyePosition(leftEye[0], secondResult: rightEye[0]) else { return }
                DispatchQueue.main.async {
                    self.eView.frame.origin = CGPoint(x: CGFloat(coords.x), y: CGFloat(coords.y))
                    self.tableContentOff(tableFlg: self.tableFlg)

                    if self.eView.frame.origin.y > self.webView.frame.height/2 {
                        self.y += self.contentOffSetY
                    } else {
                        self.y -= self.contentOffSetY
                    }
                    self.webContentOffSetX()
                    self.webEViewSet()
                }
            }
            return
        }
    }
}

// MARK: UITableViewDataSource, UITableViewDelegate
@available(iOS 11.0, *)
extension RARFObject: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RARFCell", for: indexPath)
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return indexNumber
    }
}
