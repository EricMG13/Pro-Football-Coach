import SwiftUI

/// One column of a dense table.
///
/// The cell builder is type-erased because a table's columns are heterogeneous by nature — a
/// rating cell, a status chip and a name are different views over the same row. Row counts are
/// bounded by the read models that feed them, so the erasure is affordable.
public struct DenseTableColumn<Row: Identifiable>: Identifiable {
    public let id: String
    public let title: String
    public let width: CGFloat?
    public let alignment: Alignment
    /// Non-nil makes the header cell a sort control.
    public let sortKey: String?
    /// Spoken name, where the visible title is an abbreviation. "OVR" reads as "overall".
    public let spokenTitle: String
    let cell: (Row) -> AnyView

    public init<Cell: View>(
        id: String,
        title: String,
        spokenTitle: String? = nil,
        width: CGFloat? = nil,
        alignment: Alignment = .leading,
        sortKey: String? = nil,
        @ViewBuilder cell: @escaping (Row) -> Cell
    ) {
        self.id = id
        self.title = title
        self.spokenTitle = spokenTitle ?? title
        self.width = width
        self.alignment = alignment
        self.sortKey = sortKey
        self.cell = { AnyView(cell($0)) }
    }
}

/// Which column a table is sorted by, and which way.
public struct DenseTableSort: Equatable, Sendable {
    public let key: String
    public let isAscending: Bool

    public init(key: String, isAscending: Bool) {
        self.key = key
        self.isAscending = isAscending
    }

    public var spoken: String { isAscending ? "ascending" : "descending" }
}

/// Registry 7 — 24–28 pt tracked rows, a sortable header, and a selection rule.
///
/// **This existed twice and the two copies had diverged.** `RosterView` drew 28 pt rows inside a
/// `ScrollView` with a `LazyVStack`; `RecruitingBoardView` drew 44 pt rows with neither — so the
/// recruiting board did not scroll and was not lazy, and nobody noticed because the two
/// implementations were only ever read separately. That is the case for a registry in one exhibit.
///
/// Selection takes boundary, value and spoken state per `04` §6.3 — never a coloured fill alone,
/// which is also why the fill is a wash rather than the signal.
public struct DenseTable<Row: Identifiable>: View {
    @Environment(\.coachWorldPalette) private var palette
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private let rows: [Row]
    private let columns: [DenseTableColumn<Row>]
    private let caption: String
    private let countLabel: String
    private let selection: Row.ID?
    private let sort: DenseTableSort?
    private let isUnavailable: (Row) -> Bool
    private let spokenRow: (Row) -> String
    private let onSelect: ((Row.ID) -> Void)?
    private let onSort: ((String) -> Void)?
    private let emptyState: AnyView?

    public init<Empty: View>(
        rows: [Row],
        columns: [DenseTableColumn<Row>],
        caption: String,
        countLabel: String,
        selection: Row.ID? = nil,
        sort: DenseTableSort? = nil,
        isUnavailable: @escaping (Row) -> Bool = { _ in false },
        spokenRow: @escaping (Row) -> String,
        onSelect: ((Row.ID) -> Void)? = nil,
        onSort: ((String) -> Void)? = nil,
        @ViewBuilder emptyState: () -> Empty
    ) {
        self.rows = rows
        self.columns = columns
        self.caption = caption
        self.countLabel = countLabel
        self.selection = selection
        self.sort = sort
        self.isUnavailable = isUnavailable
        self.spokenRow = spokenRow
        self.onSelect = onSelect
        self.onSort = onSort
        self.emptyState = AnyView(emptyState())
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            captionBand
            if rows.isEmpty {
                // The chrome above stays exactly as the populated table draws it; only the rows
                // region is replaced (`04` §7 — failure states stay inside their composition).
                emptyState
            } else {
                header
                rowsRegion
            }
        }
    }

    private var captionBand: some View {
        HStack {
            CoachWorldFieldLabel(caption)
            Spacer(minLength: CoachWorldTokens.Space.sm)
            Text(countLabel)
                .font(CoachWorldTokens.TypeRole.caption)
                .monospacedDigit()
                .foregroundStyle(palette.contentPrimary.color)
        }
        .padding(.horizontal, CoachWorldTokens.Table.cellInset)
        .frame(minHeight: CoachWorldTokens.Table.captionHeight)
        .accessibilityElement(children: .combine)
    }

    private var header: some View {
        HStack(spacing: CoachWorldTokens.Space.sm) {
            ForEach(columns) { column in
                headerCell(column)
            }
        }
        .padding(.horizontal, CoachWorldTokens.Table.cellInset)
        .frame(height: CoachWorldTokens.Table.headerHeight)
        .coachWorldSeam(.legible)
    }

    @ViewBuilder private func headerCell(_ column: DenseTableColumn<Row>) -> some View {
        let isSorted = sort?.key == column.sortKey && column.sortKey != nil
        Group {
            if let sortKey = column.sortKey, let onSort {
                Button { onSort(sortKey) } label: {
                    headerLabel(column, isSorted: isSorted)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(headerSpoken(column, isSorted: isSorted))
            } else {
                headerLabel(column, isSorted: false)
            }
        }
        .frame(width: column.width, alignment: column.alignment)
    }

    private func headerLabel(_ column: DenseTableColumn<Row>, isSorted: Bool) -> some View {
        HStack(spacing: CoachWorldTokens.Space.xxs) {
            Text(column.title)
                .lineLimit(1)
            if isSorted, let sort {
                Image(systemName: sort.isAscending ? "chevron.up" : "chevron.down")
                    .accessibilityHidden(true)
            }
        }
        .font(CoachWorldTokens.TypeRole.caption)
        .foregroundStyle(isSorted ? palette.actionPrimary.color : palette.contentSecondary.color)
        .frame(maxWidth: .infinity, alignment: column.alignment)
    }

    private func headerSpoken(_ column: DenseTableColumn<Row>, isSorted: Bool) -> String {
        guard isSorted, let sort else { return "Sort by \(column.spokenTitle)" }
        return "\(column.spokenTitle), sorted \(sort.spoken). Activate to reverse."
    }

    /// Lazy and scrolling, both of which one of the two prior copies lacked.
    private var rowsRegion: some View {
        ScrollView {
            LazyVStack(spacing: .zero) {
                ForEach(rows) { row in
                    rowView(row)
                }
            }
        }
    }

    private func rowView(_ row: Row) -> some View {
        let isSelected = selection == row.id
        return Group {
            if let onSelect {
                Button { onSelect(row.id) } label: { rowContent(row, isSelected: isSelected) }
                    .buttonStyle(.plain)
            } else {
                rowContent(row, isSelected: isSelected)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenRow(row))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func rowContent(_ row: Row, isSelected: Bool) -> some View {
        HStack(spacing: CoachWorldTokens.Space.sm) {
            ForEach(columns) { column in
                column.cell(row)
                    .frame(width: column.width, alignment: column.alignment)
            }
        }
        .padding(.horizontal, CoachWorldTokens.Table.cellInset)
        .frame(minHeight: rowHeight)
        .opacity(isUnavailable(row) ? CoachWorldTokens.Table.unavailableOpacity : 1)
        .background(isSelected
                    ? palette.actionPrimary.color.opacity(CoachWorldTokens.Table.selectionFillOpacity)
                    : .clear)
        .overlay(alignment: .leading) {
            if isSelected {
                Rectangle()
                    .fill(palette.actionPrimary.color)
                    .frame(width: CoachWorldTokens.Table.selectionRuleWidth)
            }
        }
        .coachWorldSeam(.structural)
    }

    /// AX5 expands and reflows the track rather than forcing micro-type into it (`04` §6.3).
    private var rowHeight: CGFloat {
        dynamicTypeSize.isAccessibilitySize
            ? CoachWorldTokens.Shape.minimumTarget
            : CoachWorldTokens.Table.rowHeight
    }
}
