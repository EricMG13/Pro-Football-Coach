import SwiftUI

// MARK: - Registry 8: ColumnSet

/// A named group of fact columns that swaps over stable identity columns.
///
/// The identity columns never move. That is the whole point: a player's row stays where it is and
/// keeps its name and number while the facts beside it change, so the reader tracks one person
/// across sets rather than re-finding them. A "set" that reorders or re-sorts is a different table
/// wearing the same control.
public struct ColumnSet<Row: Identifiable>: Identifiable {
    public let id: String
    public let title: String
    public let columns: [DenseTableColumn<Row>]

    public init(id: String, title: String, columns: [DenseTableColumn<Row>]) {
        self.id = id
        self.title = title
        self.columns = columns
    }
}

/// The control that swaps between column sets.
public struct ColumnSetControl: View {
    private let sets: [(id: String, title: String)]
    private let selected: String
    private let onSelect: (String) -> Void

    public init(
        sets: [(id: String, title: String)],
        selected: String,
        onSelect: @escaping (String) -> Void
    ) {
        self.sets = sets
        self.selected = selected
        self.onSelect = onSelect
    }

    public var body: some View {
        HStack(spacing: CoachWorldTokens.Space.xxs) {
            ForEach(sets, id: \.id) { set in
                CoachWorldRoutePill(
                    set.title,
                    isSelected: set.id == selected,
                    action: { onSelect(set.id) }
                )
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Fact columns")
    }
}

// MARK: - Registry 9: ListControls

/// Sort, filter, bounded search and multi-select over simulation objects.
///
/// **None of this existed.** The target had sorting on one screen and no filter, no search and no
/// multi-select anywhere — which is why `04` §4.5 could price a board at scale and the board could
/// not be worked at scale. The search is bounded on purpose: `WorldHistoryReadModel.search` is
/// proven over a ≤32,768-entry index with diacritic-folded AND-token matching, and this control is
/// its surface rather than a second search nobody has tested.
///
/// The controls sit **above** the dominant object and spend one secondary region of the `04` §4.5
/// budget between them — not one region each.
public struct ListControls: View {
    /// A filter the caller offers. `options` is closed: a filter over free text is a search.
    public struct Filter: Identifiable {
        public let id: String
        public let title: String
        public let options: [Option]
        public let selection: String?

        public struct Option: Identifiable {
            public let id: String
            public let title: String
            /// How many objects survive this option — printed, so a filter that would empty the
            /// list says so before it is applied rather than after.
            public let count: Int

            public init(id: String, title: String, count: Int) {
                self.id = id
                self.title = title
                self.count = count
            }
        }

        public init(id: String, title: String, options: [Option], selection: String?) {
            self.id = id
            self.title = title
            self.options = options
            self.selection = selection
        }

        var currentTitle: String {
            options.first { $0.id == selection }?.title ?? "All"
        }
    }

    @Environment(\.coachWorldPalette) private var palette

    private let searchText: String
    private let searchPrompt: String
    private let filters: [Filter]
    private let sortTitle: String?
    private let selectedCount: Int
    private let onSearch: (String) -> Void
    private let onFilter: (String, String?) -> Void
    private let onSort: (() -> Void)?
    private let onClearSelection: (() -> Void)?

    public init(
        searchText: String,
        searchPrompt: String,
        filters: [Filter] = [],
        sortTitle: String? = nil,
        selectedCount: Int = 0,
        onSearch: @escaping (String) -> Void,
        onFilter: @escaping (String, String?) -> Void,
        onSort: (() -> Void)? = nil,
        onClearSelection: (() -> Void)? = nil
    ) {
        self.searchText = searchText
        self.searchPrompt = searchPrompt
        self.filters = filters
        self.sortTitle = sortTitle
        self.selectedCount = selectedCount
        self.onSearch = onSearch
        self.onFilter = onFilter
        self.onSort = onSort
        self.onClearSelection = onClearSelection
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
            HStack(spacing: CoachWorldTokens.Space.xs) {
                search
                ForEach(filters) { filter in
                    filterMenu(filter)
                }
                if let sortTitle, let onSort {
                    GoButton(sortTitle, kind: .ghost, size: .compact, action: onSort)
                }
            }
            if selectedCount > 0 {
                bulkBar
            }
        }
    }

    private var search: some View {
        HStack(spacing: CoachWorldTokens.Space.xxs) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(palette.contentQuiet.color)
                .accessibilityHidden(true)
            TextField(
                searchPrompt,
                text: Binding(get: { searchText }, set: onSearch)
            )
            .font(CoachWorldTokens.TypeRole.body)
            .textFieldStyle(.plain)
            .autocorrectionDisabled()
        }
        .padding(.horizontal, CoachWorldTokens.Space.sm)
        .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
        .background(CutCorner.row.fill(CoachWorldTokens.Control.ghostFill.color))
        .overlay(CutCorner.row.strokeBorder(
            CoachWorldTokens.Glass.edge.color,
            lineWidth: CoachWorldTokens.Shape.hairline
        ))
        .accessibilityLabel(searchPrompt)
    }

    private func filterMenu(_ filter: Filter) -> some View {
        Menu {
            Button("All") { onFilter(filter.id, nil) }
            ForEach(filter.options) { option in
                Button("\(option.title) (\(option.count))") { onFilter(filter.id, option.id) }
            }
        } label: {
            HStack(spacing: CoachWorldTokens.Space.xxs) {
                Text("\(filter.title): \(filter.currentTitle)")
                    .font(CoachWorldTokens.TypeRole.caption)
                    .lineLimit(1)
                Image(systemName: "line.3.horizontal.decrease")
                    .accessibilityHidden(true)
            }
            .foregroundStyle(palette.contentSecondary.color)
            .padding(.horizontal, CoachWorldTokens.Space.sm)
            .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
            .overlay(CutCorner.row.strokeBorder(
                CoachWorldTokens.Glass.edge.color,
                lineWidth: CoachWorldTokens.Shape.hairline
            ))
        }
        .accessibilityLabel("\(filter.title) filter, \(filter.currentTitle)")
    }

    /// The bulk bar appears only with a selection, and states the count as a fact before offering
    /// anything that acts on it.
    private var bulkBar: some View {
        HStack(spacing: CoachWorldTokens.Space.sm) {
            Text("\(selectedCount) selected")
                .font(CoachWorldTokens.TypeRole.callout)
                .monospacedDigit()
                .foregroundStyle(palette.contentPrimary.color)
            if let onClearSelection {
                GoButton("Clear", kind: .ghost, size: .compact, action: onClearSelection)
            }
        }
        .padding(.horizontal, CoachWorldTokens.Space.sm)
        .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
        .background(CutCorner.row.fill(
            palette.actionPrimary.color.opacity(CoachWorldTokens.Table.selectionFillOpacity)
        ))
        .accessibilityElement(children: .contain)
    }
}
