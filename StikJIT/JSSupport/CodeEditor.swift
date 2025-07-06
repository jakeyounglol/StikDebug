import SwiftUI
import UIKit

class LineNumberTextView: UITextView {
    private let lineNumberView = UITextView()
    private let lineNumberWidth: CGFloat = 40

    override var text: String! {
        didSet { updateLineNumbers() }
    }

    override var font: UIFont? {
        didSet { lineNumberView.font = font }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setup()
    }

    private func setup() {
        lineNumberView.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        lineNumberView.textColor = .gray
        lineNumberView.isEditable = false
        lineNumberView.textAlignment = .right
        lineNumberView.isScrollEnabled = false
        addSubview(lineNumberView)
        textContainerInset.left = lineNumberWidth + 4
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        lineNumberView.frame = CGRect(x: 0, y: 0, width: lineNumberWidth, height: bounds.height)
    }

    func updateLineNumbers() {
        let lineCount = text.components(separatedBy: "\n").count
        lineNumberView.text = (1...max(lineCount,1)).map { String($0) }.joined(separator: "\n")
    }
}

struct CodeEditor: UIViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> LineNumberTextView {
        let textView = LineNumberTextView()
        textView.delegate = context.coordinator
        textView.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.smartDashesType = .no
        textView.smartQuotesType = .no
        textView.backgroundColor = UIColor.systemBackground
        return textView
    }

    func updateUIView(_ uiView: LineNumberTextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
            uiView.updateLineNumbers()
        }
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: CodeEditor
        init(_ parent: CodeEditor) { self.parent = parent }
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            if let ln = textView as? LineNumberTextView { ln.updateLineNumbers() }
        }
    }
}
