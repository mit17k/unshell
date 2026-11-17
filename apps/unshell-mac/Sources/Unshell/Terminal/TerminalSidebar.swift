import AppKit

/// Plain AppKit table: cheap row reuse and targeted reloads, so 50 terminals
/// with animated titles don't cost a full re-layout.
final class TerminalSidebar: NSView, NSTableViewDataSource, NSTableViewDelegate {
    var onSelect: ((Int) -> Void)?
    var terminals: [TerminalSurfaceView] = [] {
        didSet { table.reloadData() }
    }

    private let scroll = NSScrollView()
    private let table = NSTableView()
    private var isProgrammaticSelection = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        let column = NSTableColumn(identifier: .init("terminal"))
        table.addTableColumn(column)
        table.headerView = nil
        table.rowHeight = 26
        table.intercellSpacing = .zero
        table.backgroundColor = .clear
        table.selectionHighlightStyle = .regular
        table.style = .plain
        table.dataSource = self
        table.delegate = self

        scroll.documentView = table
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = true
        scroll.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(equalTo: leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: trailingAnchor),
            scroll.topAnchor.constraint(equalTo: topAnchor),
            scroll.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("not used") }

    func select(_ index: Int) {
        isProgrammaticSelection = true
        table.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
        table.scrollRowToVisible(index)
        isProgrammaticSelection = false
    }

    func reloadRows(_ rows: IndexSet) {
        let valid = rows.filteredIndexSet { $0 < terminals.count }
        guard !valid.isEmpty else { return }
        table.reloadData(forRowIndexes: valid, columnIndexes: IndexSet(integer: 0))
    }

    func numberOfRows(in tableView: NSTableView) -> Int { terminals.count }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let id = NSUserInterfaceItemIdentifier("cell")
        let cell = (tableView.makeView(withIdentifier: id, owner: self) as? NSTableCellView) ?? {
            let cell = NSTableCellView()
            cell.identifier = id
            let label = NSTextField(labelWithString: "")
            label.font = Theme.Font.mono
            label.textColor = Theme.Color.fg
            label.lineBreakMode = .byTruncatingTail
            label.translatesAutoresizingMaskIntoConstraints = false
            cell.addSubview(label)
            cell.textField = label
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 12),
                label.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -8),
                label.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
            ])
            return cell
        }()
        cell.textField?.stringValue = String(format: "%02d  %@", row + 1, terminals[row].title)
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard !isProgrammaticSelection, table.selectedRow >= 0 else { return }
        onSelect?(table.selectedRow)
    }
}
