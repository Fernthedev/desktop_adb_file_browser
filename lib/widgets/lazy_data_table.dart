import 'package:flutter/material.dart';
import 'dart:math' as math;

typedef CellBuilder = List<DataCell> Function(BuildContext context, int i);

class LazyDataTable extends DataTable {
  LazyDataTable(
      {super.key,
      required super.rows,
      required this.rowCount,
      required this.cellBuilder,
      required super.columns,
      super.sortAscending,
      super.sortColumnIndex})
      : _onlyTextColumn = _initOnlyTextColumn(columns);

  final int rowCount;
  final CellBuilder cellBuilder;

  static final LocalKey _headingRowKey = UniqueKey();

  /// The default height of the heading row.
  static const double _headingRowHeight = 56.0;

  /// The default horizontal margin between the edges of the table and the content
  /// in the first and last cells of each row.
  static const double _horizontalMargin = 24.0;

  /// The default horizontal margin between the contents of each data column.
  static const double _columnSpacing = 56.0;

  /// The default padding between the heading content and sort arrow.
  static const double _sortArrowPadding = 2.0;

  /// The default divider thickness.
  static const double _dividerThickness = 1.0;

  static const Duration _sortArrowAnimationDuration =
      Duration(milliseconds: 150);

  // Set by the constructor to the index of the only Column that is
  // non-numeric, if there is exactly one, otherwise null.
  final int? _onlyTextColumn;
  static int? _initOnlyTextColumn(List<DataColumn> columns) {
    int? result;
    for (int index = 0; index < columns.length; index += 1) {
      final DataColumn column = columns[index];
      if (!column.numeric) {
        if (result != null) {
          return null;
        }
        result = index;
      }
    }
    return result;
  }

  Widget _buildHeadingCell({
    required BuildContext context,
    required EdgeInsetsGeometry padding,
    required Widget label,
    required String? tooltip,
    required bool numeric,
    required VoidCallback? onSort,
    required bool sorted,
    required bool ascending,
    required MaterialStateProperty<Color?>? overlayColor,
    required MouseCursor? mouseCursor,
  }) {
    final ThemeData themeData = Theme.of(context);
    final DataTableThemeData dataTableTheme = DataTableTheme.of(context);
    label = Row(
      textDirection: numeric ? TextDirection.rtl : null,
      children: <Widget>[
        label,
        if (onSort != null) ...<Widget>[
          _SortArrow(
            visible: sorted,
            up: sorted ? ascending : null,
            duration: _sortArrowAnimationDuration,
          ),
          const SizedBox(width: _sortArrowPadding),
        ],
      ],
    );

    final TextStyle effectiveHeadingTextStyle = headingTextStyle ??
        dataTableTheme.headingTextStyle ??
        themeData.dataTableTheme.headingTextStyle ??
        themeData.textTheme.titleSmall!;
    final double effectiveHeadingRowHeight = headingRowHeight ??
        dataTableTheme.headingRowHeight ??
        themeData.dataTableTheme.headingRowHeight ??
        _headingRowHeight;
    label = Container(
      padding: padding,
      height: effectiveHeadingRowHeight,
      alignment:
          numeric ? Alignment.centerRight : AlignmentDirectional.centerStart,
      child: AnimatedDefaultTextStyle(
        style: effectiveHeadingTextStyle,
        softWrap: false,
        duration: _sortArrowAnimationDuration,
        child: label,
      ),
    );
    if (tooltip != null) {
      label = Tooltip(
        message: tooltip,
        child: label,
      );
    }

    // TODO(dkwingsmt): Only wrap Inkwell if onSort != null. Blocked by
    // https://github.com/flutter/flutter/issues/51152
    label = InkWell(
      onTap: onSort,
      overlayColor: overlayColor,
      mouseCursor: mouseCursor,
      child: label,
    );
    return label;
  }

  Widget _buildDataCell({
    required BuildContext context,
    required EdgeInsetsGeometry padding,
    required Widget label,
    required bool numeric,
    required bool placeholder,
    required bool showEditIcon,
    required GestureTapCallback? onTap,
    required VoidCallback? onSelectChanged,
    required GestureTapCallback? onDoubleTap,
    required GestureLongPressCallback? onLongPress,
    required GestureTapDownCallback? onTapDown,
    required GestureTapCancelCallback? onTapCancel,
    required MaterialStateProperty<Color?>? overlayColor,
    required GestureLongPressCallback? onRowLongPress,
    required MouseCursor? mouseCursor,
  }) {
    final ThemeData themeData = Theme.of(context);
    final DataTableThemeData dataTableTheme = DataTableTheme.of(context);
    if (showEditIcon) {
      const Widget icon = Icon(Icons.edit, size: 18.0);
      label = Expanded(child: label);
      label = Row(
        textDirection: numeric ? TextDirection.rtl : null,
        children: <Widget>[label, icon],
      );
    }

    final TextStyle effectiveDataTextStyle = dataTextStyle ??
        dataTableTheme.dataTextStyle ??
        themeData.dataTableTheme.dataTextStyle ??
        themeData.textTheme.bodyMedium!;
    final double effectiveDataRowMinHeight = dataRowMinHeight ??
        dataTableTheme.dataRowMinHeight ??
        themeData.dataTableTheme.dataRowMinHeight ??
        kMinInteractiveDimension;
    final double effectiveDataRowMaxHeight = dataRowMaxHeight ??
        dataTableTheme.dataRowMaxHeight ??
        themeData.dataTableTheme.dataRowMaxHeight ??
        kMinInteractiveDimension;
    label = Container(
      padding: padding,
      constraints: BoxConstraints(
          minHeight: effectiveDataRowMinHeight,
          maxHeight: effectiveDataRowMaxHeight),
      alignment:
          numeric ? Alignment.centerRight : AlignmentDirectional.centerStart,
      child: DefaultTextStyle(
        style: effectiveDataTextStyle.copyWith(
          color: placeholder
              ? effectiveDataTextStyle.color!.withOpacity(0.6)
              : null,
        ),
        child: DropdownButtonHideUnderline(child: label),
      ),
    );
    if (onTap != null ||
        onDoubleTap != null ||
        onLongPress != null ||
        onTapDown != null ||
        onTapCancel != null) {
      label = InkWell(
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        onLongPress: onLongPress,
        onTapCancel: onTapCancel,
        onTapDown: onTapDown,
        overlayColor: overlayColor,
        child: label,
      );
    } else if (onSelectChanged != null || onRowLongPress != null) {
      label = TableRowInkWell(
        onTap: onSelectChanged,
        onLongPress: onRowLongPress,
        overlayColor: overlayColor,
        mouseCursor: mouseCursor,
        child: label,
      );
    }
    return label;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    assert(debugCheckHasMaterial(context));

    final ThemeData theme = Theme.of(context);
    final DataTableThemeData dataTableTheme = DataTableTheme.of(context);
    final MaterialStateProperty<Color?>? effectiveHeadingRowColor =
        headingRowColor ??
            dataTableTheme.headingRowColor ??
            theme.dataTableTheme.headingRowColor;
    final MaterialStateProperty<Color?>? effectiveDataRowColor = dataRowColor ??
        dataTableTheme.dataRowColor ??
        theme.dataTableTheme.dataRowColor;
    final MaterialStateProperty<Color?> defaultRowColor =
        MaterialStateProperty.resolveWith(
      (Set<MaterialState> states) {
        if (states.contains(MaterialState.selected)) {
          return theme.colorScheme.primary.withOpacity(0.08);
        }
        return null;
      },
    );
    final bool anyRowSelectable =
        rows.any((DataRow row) => row.onSelectChanged != null);
    final bool displayCheckboxColumn = showCheckboxColumn && anyRowSelectable;
    final Iterable<DataRow> rowsWithCheckbox = displayCheckboxColumn
        ? rows.where((DataRow row) => row.onSelectChanged != null)
        : <DataRow>[];
    final Iterable<DataRow> rowsChecked =
        rowsWithCheckbox.where((DataRow row) => row.selected);
    final bool allChecked =
        displayCheckboxColumn && rowsChecked.length == rowsWithCheckbox.length;
    final bool anyChecked = displayCheckboxColumn && rowsChecked.isNotEmpty;
    final bool someChecked = anyChecked && !allChecked;
    final double effectiveHorizontalMargin = horizontalMargin ??
        dataTableTheme.horizontalMargin ??
        theme.dataTableTheme.horizontalMargin ??
        _horizontalMargin;
    final double effectiveCheckboxHorizontalMarginStart =
        checkboxHorizontalMargin ??
            dataTableTheme.checkboxHorizontalMargin ??
            theme.dataTableTheme.checkboxHorizontalMargin ??
            effectiveHorizontalMargin;
    final double effectiveCheckboxHorizontalMarginEnd =
        checkboxHorizontalMargin ??
            dataTableTheme.checkboxHorizontalMargin ??
            theme.dataTableTheme.checkboxHorizontalMargin ??
            effectiveHorizontalMargin / 2.0;
    final double effectiveColumnSpacing = columnSpacing ??
        dataTableTheme.columnSpacing ??
        theme.dataTableTheme.columnSpacing ??
        _columnSpacing;

    final List<TableColumnWidth> tableColumns = List<TableColumnWidth>.filled(
        columns.length + (displayCheckboxColumn ? 1 : 0),
        const _NullTableColumnWidth());
    final List<TableRow> tableRows = List<TableRow>.generate(
      rowCount + 1, // the +1 is for the header row
      (int index) {
        final bool isSelected = index > 0 && rows[index - 1].selected;
        final bool isDisabled = index > 0 &&
            anyRowSelectable &&
            rows[index - 1].onSelectChanged == null;
        final Set<MaterialState> states = <MaterialState>{
          if (isSelected) MaterialState.selected,
          if (isDisabled) MaterialState.disabled,
        };
        final Color? resolvedDataRowColor = index > 0
            ? (rows[index - 1].color ?? effectiveDataRowColor)?.resolve(states)
            : null;
        final Color? resolvedHeadingRowColor =
            effectiveHeadingRowColor?.resolve(<MaterialState>{});
        final Color? rowColor =
            index > 0 ? resolvedDataRowColor : resolvedHeadingRowColor;
        final BorderSide borderSide = Divider.createBorderSide(
          context,
          width: dividerThickness ??
              dataTableTheme.dividerThickness ??
              theme.dataTableTheme.dividerThickness ??
              _dividerThickness,
        );
        final Border? border = showBottomBorder
            ? Border(bottom: borderSide)
            : index == 0
                ? null
                : Border(top: borderSide);
        return TableRow(
          key: index == 0 ? _headingRowKey : rows[index - 1].key,
          decoration: BoxDecoration(
            border: border,
            color: rowColor ?? defaultRowColor.resolve(states),
          ),
          children:
              List<Widget>.filled(tableColumns.length, const _NullWidget()),
        );
      },
    );

    int rowIndex;

    int displayColumnIndex = 0;
    // - Fern
    // if (displayCheckboxColumn) {
    //   tableColumns[0] = FixedColumnWidth(
    //       effectiveCheckboxHorizontalMarginStart +
    //           Checkbox.width +
    //           effectiveCheckboxHorizontalMarginEnd);
    //   tableRows[0].children[0] = super._buildCheckbox(
    //     context: context,
    //     checked: someChecked ? null : allChecked,
    //     onRowTap: null,
    //     onCheckboxChanged: (bool? checked) =>
    //         _handleSelectAll(checked, someChecked),
    //     overlayColor: null,
    //     tristate: true,
    //   );
    //   rowIndex = 1;
    //   for (final DataRow row in rows) {
    //     final Set<MaterialState> states = <MaterialState>{
    //       if (row.selected) MaterialState.selected,
    //     };
    //     tableRows[rowIndex].children[0] = _buildCheckbox(
    //       context: context,
    //       checked: row.selected,
    //       onRowTap: row.onSelectChanged == null
    //           ? null
    //           : () => row.onSelectChanged?.call(!row.selected),
    //       onCheckboxChanged: row.onSelectChanged,
    //       overlayColor: row.color ?? effectiveDataRowColor,
    //       rowMouseCursor: row.mouseCursor?.resolve(states) ??
    //           dataTableTheme.dataRowCursor?.resolve(states),
    //       tristate: false,
    //     );
    //     rowIndex += 1;
    //   }
    //   displayColumnIndex += 1;
    // }

    for (int dataColumnIndex = 0;
        dataColumnIndex < columns.length;
        dataColumnIndex += 1) {
      final DataColumn column = columns[dataColumnIndex];

      final double paddingStart;
      if (dataColumnIndex == 0 &&
          displayCheckboxColumn &&
          checkboxHorizontalMargin != null) {
        paddingStart = effectiveHorizontalMargin;
      } else if (dataColumnIndex == 0 && displayCheckboxColumn) {
        paddingStart = effectiveHorizontalMargin / 2.0;
      } else if (dataColumnIndex == 0 && !displayCheckboxColumn) {
        paddingStart = effectiveHorizontalMargin;
      } else {
        paddingStart = effectiveColumnSpacing / 2.0;
      }

      final double paddingEnd;
      if (dataColumnIndex == columns.length - 1) {
        paddingEnd = effectiveHorizontalMargin;
      } else {
        paddingEnd = effectiveColumnSpacing / 2.0;
      }

      final EdgeInsetsDirectional padding = EdgeInsetsDirectional.only(
        start: paddingStart,
        end: paddingEnd,
      );
      if (dataColumnIndex == _onlyTextColumn) {
        tableColumns[displayColumnIndex] =
            const IntrinsicColumnWidth(flex: 1.0);
      } else {
        tableColumns[displayColumnIndex] = const IntrinsicColumnWidth();
      }
      final Set<MaterialState> headerStates = <MaterialState>{
        if (column.onSort == null) MaterialState.disabled,
      };
      tableRows[0].children[displayColumnIndex] = _buildHeadingCell(
        context: context,
        padding: padding,
        label: column.label,
        tooltip: column.tooltip,
        numeric: column.numeric,
        onSort: column.onSort != null
            ? () => column.onSort!(dataColumnIndex,
                sortColumnIndex != dataColumnIndex || !sortAscending)
            : null,
        sorted: dataColumnIndex == sortColumnIndex,
        ascending: sortAscending,
        overlayColor: effectiveHeadingRowColor,
        mouseCursor: column.mouseCursor?.resolve(headerStates) ??
            dataTableTheme.headingCellCursor?.resolve(headerStates),
      );
      rowIndex = 1;
      for (final DataRow row in rows) {
        final Set<MaterialState> states = <MaterialState>{
          if (row.selected) MaterialState.selected,
        };
        final DataCell cell = row.cells[dataColumnIndex];
        tableRows[rowIndex].children[displayColumnIndex] = _buildDataCell(
          context: context,
          padding: padding,
          label: cell.child,
          numeric: column.numeric,
          placeholder: cell.placeholder,
          showEditIcon: cell.showEditIcon,
          onTap: cell.onTap,
          onDoubleTap: cell.onDoubleTap,
          onLongPress: cell.onLongPress,
          onTapCancel: cell.onTapCancel,
          onTapDown: cell.onTapDown,
          onSelectChanged: row.onSelectChanged == null
              ? null
              : () => row.onSelectChanged?.call(!row.selected),
          overlayColor: row.color ?? effectiveDataRowColor,
          onRowLongPress: row.onLongPress,
          mouseCursor: row.mouseCursor?.resolve(states) ??
              dataTableTheme.dataRowCursor?.resolve(states),
        );
        rowIndex += 1;
      }
      displayColumnIndex += 1;
    }

    return Container(
      decoration: decoration ??
          dataTableTheme.decoration ??
          theme.dataTableTheme.decoration,
      child: Material(
        type: MaterialType.transparency,
        borderRadius: border?.borderRadius,
        clipBehavior: clipBehavior,
        child: Table(
          columnWidths: tableColumns.asMap(),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: tableRows,
          border: border,
        ),
      ),
    );
  }
}

class _NullTableColumnWidth extends TableColumnWidth {
  const _NullTableColumnWidth();

  @override
  double maxIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) =>
      throw UnimplementedError();

  @override
  double minIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) =>
      throw UnimplementedError();
}

class _NullWidget extends Widget {
  const _NullWidget();

  @override
  Element createElement() => throw UnimplementedError();
}

class _SortArrow extends StatefulWidget {
  const _SortArrow({
    required this.visible,
    required this.up,
    required this.duration,
  });

  final bool visible;

  final bool? up;

  final Duration duration;

  @override
  _SortArrowState createState() => _SortArrowState();
}

class _SortArrowState extends State<_SortArrow> with TickerProviderStateMixin {
  late AnimationController _opacityController;
  late Animation<double> _opacityAnimation;

  late AnimationController _orientationController;
  late Animation<double> _orientationAnimation;
  double _orientationOffset = 0.0;

  bool? _up;

  static final Animatable<double> _turnTween =
      Tween<double>(begin: 0.0, end: math.pi)
          .chain(CurveTween(curve: Curves.easeIn));

  @override
  void initState() {
    super.initState();
    _up = widget.up;
    _opacityAnimation = CurvedAnimation(
      parent: _opacityController = AnimationController(
        duration: widget.duration,
        vsync: this,
      ),
      curve: Curves.fastOutSlowIn,
    )..addListener(_rebuild);
    _opacityController.value = widget.visible ? 1.0 : 0.0;
    _orientationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _orientationAnimation = _orientationController.drive(_turnTween)
      ..addListener(_rebuild)
      ..addStatusListener(_resetOrientationAnimation);
    if (widget.visible) {
      _orientationOffset = widget.up! ? 0.0 : math.pi;
    }
  }

  void _rebuild() {
    setState(() {
      // The animations changed, so we need to rebuild.
    });
  }

  void _resetOrientationAnimation(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      assert(_orientationAnimation.value == math.pi);
      _orientationOffset += math.pi;
      _orientationController.value =
          0.0; // TODO(ianh): This triggers a pointless rebuild.
    }
  }

  @override
  void didUpdateWidget(_SortArrow oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool skipArrow = false;
    final bool? newUp = widget.up ?? _up;
    if (oldWidget.visible != widget.visible) {
      if (widget.visible &&
          (_opacityController.status == AnimationStatus.dismissed)) {
        _orientationController.stop();
        _orientationController.value = 0.0;
        _orientationOffset = newUp! ? 0.0 : math.pi;
        skipArrow = true;
      }
      if (widget.visible) {
        _opacityController.forward();
      } else {
        _opacityController.reverse();
      }
    }
    if ((_up != newUp) && !skipArrow) {
      if (_orientationController.status == AnimationStatus.dismissed) {
        _orientationController.forward();
      } else {
        _orientationController.reverse();
      }
    }
    _up = newUp;
  }

  @override
  void dispose() {
    _opacityController.dispose();
    _orientationController.dispose();
    super.dispose();
  }

  static const double _arrowIconBaselineOffset = -1.5;
  static const double _arrowIconSize = 16.0;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: Transform(
        transform:
            Matrix4.rotationZ(_orientationOffset + _orientationAnimation.value)
              ..setTranslationRaw(0.0, _arrowIconBaselineOffset, 0.0),
        alignment: Alignment.center,
        child: const Icon(
          Icons.arrow_upward,
          size: _arrowIconSize,
        ),
      ),
    );
  }
}
