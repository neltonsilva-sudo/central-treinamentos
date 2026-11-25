// App do Mac da Central de Treinamentos: uma janela própria (WebKit) que abre a Central publicada.
// Compilar: app-mac/build.sh   (gera downloads/Treinamentos.dmg)
import Cocoa
import WebKit
import UniformTypeIdentifiers

let START = URL(string: "https://neltonsilva-sudo.github.io/central-treinamentos/?app=mac")!
let HOST = "neltonsilva-sudo.github.io"

final class AppDelegate: NSObject, NSApplicationDelegate, WKNavigationDelegate, WKUIDelegate, WKDownloadDelegate {
    var window: NSWindow!
    var web: WKWebView!

    func applicationDidFinishLaunching(_ n: Notification) {
        buildMenu()
        let cfg = WKWebViewConfiguration()
        cfg.preferences.isElementFullscreenEnabled = true
        cfg.mediaTypesRequiringUserActionForPlayback = []
        // avisa a Central que ela está dentro do app (só na página principal, não nos simuladores)
        cfg.userContentController.addUserScript(WKUserScript(source: "window.__APP_SHELL__='mac';", injectionTime: .atDocumentStart, forMainFrameOnly: true))
        web = WKWebView(frame: .zero, configuration: cfg)
        web.navigationDelegate = self
        web.uiDelegate = self
        web.allowsBackForwardNavigationGestures = true
        web.allowsMagnification = true
        web.customUserAgent = nil

        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1320, height: 860),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                          backing: .buffered, defer: false)
        window.title = "Treinamentos"
        window.minSize = NSSize(width: 420, height: 520)
        window.contentView = web
        window.center()
        window.setFrameAutosaveName("JanelaPrincipal")
        window.collectionBehavior = [.fullScreenPrimary]
        window.makeKeyAndOrderFront(nil)
        web.load(URLRequest(url: START))
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ s: NSApplication) -> Bool { true }

    // ---------- menus (⌘Q, copiar/colar, recarregar, tela cheia) ----------
    func buildMenu() {
        let main = NSMenu()
        let appItem = NSMenuItem(); main.addItem(appItem)
        let app = NSMenu()
        app.addItem(withTitle: "Sobre Treinamentos", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        app.addItem(.separator())
        app.addItem(withTitle: "Ocultar Treinamentos", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        app.addItem(.separator())
        app.addItem(withTitle: "Sair de Treinamentos", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = app

        let editItem = NSMenuItem(); main.addItem(editItem)
        let edit = NSMenu(title: "Editar")
        edit.addItem(withTitle: "Desfazer", action: Selector(("undo:")), keyEquivalent: "z")
        edit.addItem(withTitle: "Refazer", action: Selector(("redo:")), keyEquivalent: "Z")
        edit.addItem(.separator())
        edit.addItem(withTitle: "Recortar", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        edit.addItem(withTitle: "Copiar", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: "Colar", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        edit.addItem(withTitle: "Selecionar Tudo", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editItem.submenu = edit

        let viewItem = NSMenuItem(); main.addItem(viewItem)
        let view = NSMenu(title: "Visualizar")
        view.addItem(withTitle: "Início (Central)", action: #selector(goHome), keyEquivalent: "1")
        view.addItem(withTitle: "Recarregar", action: #selector(reload), keyEquivalent: "r")
        view.addItem(.separator())
        let fs = view.addItem(withTitle: "Tela Cheia", action: #selector(NSWindow.toggleFullScreen(_:)), keyEquivalent: "f")
        fs.keyEquivalentModifierMask = [.command, .control]
        viewItem.submenu = view

        let winItem = NSMenuItem(); main.addItem(winItem)
        let win = NSMenu(title: "Janela")
        win.addItem(withTitle: "Minimizar", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        win.addItem(withTitle: "Fechar", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        winItem.submenu = win
        NSApp.windowsMenu = win
        NSApp.mainMenu = main
    }
    @objc func reload() { web.reload() }
    @objc func goHome() { web.load(URLRequest(url: START)) }

    // ---------- navegação: o site fica no app, links de fora vão para o navegador ----------
    func webView(_ w: WKWebView, decidePolicyFor a: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if a.shouldPerformDownload { decisionHandler(.download); return }
        guard let url = a.request.url else { decisionHandler(.allow); return }
        let scheme = url.scheme ?? ""
        if scheme == "about" || scheme == "blob" || scheme == "data" { decisionHandler(.allow); return }
        let mainFrame = a.targetFrame?.isMainFrame ?? true
        if mainFrame && url.host != HOST && (scheme == "http" || scheme == "https" || scheme == "mailto") {
            NSWorkspace.shared.open(url); decisionHandler(.cancel); return
        }
        decisionHandler(.allow)
    }
    func webView(_ w: WKWebView, decidePolicyFor r: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(r.canShowMIMEType ? .allow : .download)
    }
    func webView(_ w: WKWebView, navigationAction: WKNavigationAction, didBecome d: WKDownload) { d.delegate = self }
    func webView(_ w: WKWebView, navigationResponse: WKNavigationResponse, didBecome d: WKDownload) { d.delegate = self }
    func download(_ d: WKDownload, decideDestinationUsing r: URLResponse, suggestedFilename name: String, completionHandler: @escaping (URL?) -> Void) {
        let dir = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
        var dest = dir.appendingPathComponent(name)
        let base = dest.deletingPathExtension().lastPathComponent, ext = dest.pathExtension
        var k = 1
        while FileManager.default.fileExists(atPath: dest.path) {
            dest = dir.appendingPathComponent(ext.isEmpty ? "\(base) (\(k))" : "\(base) (\(k)).\(ext)"); k += 1
        }
        completionHandler(dest)
    }
    func downloadDidFinish(_ d: WKDownload) { NSSound(named: "Glass")?.play() }

    // janelas novas (target=_blank, window.open): abrem no navegador padrão
    func webView(_ w: WKWebView, createWebViewWith c: WKWebViewConfiguration, for a: WKNavigationAction, windowFeatures f: WKWindowFeatures) -> WKWebView? {
        if let url = a.request.url {
            if url.host == HOST { w.load(URLRequest(url: url)) } else { NSWorkspace.shared.open(url) }
        }
        return nil
    }

    // ---------- câmera e microfone (Inspeção SST) ----------
    func webView(_ w: WKWebView, requestMediaCapturePermissionFor o: WKSecurityOrigin, initiatedByFrame f: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        decisionHandler(o.host == HOST ? .grant : .prompt)
    }

    // ---------- alert / confirm / prompt / escolher arquivo ----------
    func webView(_ w: WKWebView, runJavaScriptAlertPanelWithMessage m: String, initiatedByFrame f: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let a = NSAlert(); a.messageText = m; a.addButton(withTitle: "OK")
        a.beginSheetModal(for: window) { _ in completionHandler() }
    }
    func webView(_ w: WKWebView, runJavaScriptConfirmPanelWithMessage m: String, initiatedByFrame f: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let a = NSAlert(); a.messageText = m; a.addButton(withTitle: "OK"); a.addButton(withTitle: "Cancelar")
        a.beginSheetModal(for: window) { r in completionHandler(r == .alertFirstButtonReturn) }
    }
    func webView(_ w: WKWebView, runJavaScriptTextInputPanelWithPrompt p: String, defaultText d: String?, initiatedByFrame f: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let a = NSAlert(); a.messageText = p; a.addButton(withTitle: "OK"); a.addButton(withTitle: "Cancelar")
        let tf = NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24)); tf.stringValue = d ?? ""; a.accessoryView = tf
        a.beginSheetModal(for: window) { r in completionHandler(r == .alertFirstButtonReturn ? tf.stringValue : nil) }
    }
    func webView(_ w: WKWebView, runOpenPanelWith p: WKOpenPanelParameters, initiatedByFrame f: WKFrameInfo, completionHandler: @escaping ([URL]?) -> Void) {
        let o = NSOpenPanel(); o.allowsMultipleSelection = p.allowsMultipleSelection
        o.canChooseDirectories = p.allowsDirectories; o.canChooseFiles = true
        o.beginSheetModal(for: window) { r in completionHandler(r == .OK ? o.urls : nil) }
    }

    // sem internet: mensagem simples com "Tentar de novo"
    func webView(_ w: WKWebView, didFailProvisionalNavigation n: WKNavigation!, withError e: Error) {
        let html = """
        <html><body style="font:16px -apple-system;display:grid;place-items:center;height:100vh;margin:0;background:#070a16;color:#eef1fb;text-align:center">
        <div><h2>Sem conexão</h2><p style="opacity:.7">A Central de Treinamentos precisa de internet.</p>
        <p><a href="\(START.absoluteString)" style="color:#93c5fd">Tentar de novo</a></p></div></body></html>
        """
        w.loadHTMLString(html, baseURL: nil)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
