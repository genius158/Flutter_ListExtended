import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ScrollableExtended extends SingleChildRenderObjectWidget {
  Direction direction;

  ScrollableExtended(Widget child, {this.direction = Direction.top})
      : super(child: child);

  @override
  _SpacePadding createRenderObject(BuildContext context) {
    return _SpacePadding(direction, padding: EdgeInsets.only());
  }

  @override
  void updateRenderObject(BuildContext context, _SpacePadding renderObject) {
    renderObject..direction = direction;
  }

  @override
  SingleChildRenderObjectElement createElement() {
    return _SpaceElement(this);
  }
}

class _SpaceElement extends SingleChildRenderObjectElement {
  _SpaceElement(SingleChildRenderObjectWidget widget) : super(widget);

  @override
  void mount(Element parent, newSlot) {
    super.mount(parent, newSlot);
    findComponentInContent();
  }

  @override
  void update(SingleChildRenderObjectWidget newWidget) {
    super.update(newWidget);
    findComponentInContent();
  }

  findComponentInContent() {
    var ctx = Scrollable.of(this).context;
    findViewportRender(ctx);
    findRenderSliver(ctx);
  }

  void findViewportRender(Element element) {
    if (element.renderObject is RenderViewport) {
      (renderObject as _SpacePadding)._setComponent(element.renderObject);
      return;
    }
    element.visitChildren(findViewportRender);
  }

  void findRenderSliver(Element element) {
    if (element.renderObject is RenderSliver) {
      (renderObject as _SpacePadding)._setRenderSliver(element.renderObject);
      return;
    }
    element.visitChildren(findRenderSliver);
  }
}

class _SpacePadding extends RenderShiftedBox {
  _SpacePadding(
    this.direction, {
    @required EdgeInsetsGeometry padding,
    TextDirection textDirection,
    RenderBox child,
  })  : _padding = padding,
        super(child);

  EdgeInsets _padding;
  Direction direction;

  @override
  double computeMinIntrinsicWidth(double height) {
    final double totalHorizontalPadding = _padding.left + _padding.right;
    final double totalVerticalPadding = _padding.top + _padding.bottom;
    if (child != null) // next line relies on double.infinity absorption
      return child.getMinIntrinsicWidth(
              math.max(0.0, height - totalVerticalPadding)) +
          totalHorizontalPadding;
    return totalHorizontalPadding;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    final double totalHorizontalPadding = _padding.left + _padding.right;
    final double totalVerticalPadding = _padding.top + _padding.bottom;
    if (child != null) // next line relies on double.infinity absorption
      return child.getMaxIntrinsicWidth(
              math.max(0.0, height - totalVerticalPadding)) +
          totalHorizontalPadding;
    return totalHorizontalPadding;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    final double totalHorizontalPadding = _padding.left + _padding.right;
    final double totalVerticalPadding = _padding.top + _padding.bottom;
    if (child != null) // next line relies on double.infinity absorption
      return child.getMinIntrinsicHeight(
              math.max(0.0, width - totalHorizontalPadding)) +
          totalVerticalPadding;
    return totalVerticalPadding;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    final double totalHorizontalPadding = _padding.left + _padding.right;
    final double totalVerticalPadding = _padding.top + _padding.bottom;
    if (child != null) // next line relies on double.infinity absorption
      return child.getMaxIntrinsicHeight(
              math.max(0.0, width - totalHorizontalPadding)) +
          totalVerticalPadding;
    return totalVerticalPadding;
  }

  @override
  void performLayout() {
    assert(_padding != null);
    if (child == null) {
      size = constraints.constrain(Size(
        _padding.left + _padding.right,
        _padding.top + _padding.bottom,
      ));
      return;
    }
    final BoxConstraints innerConstraints = constraints.deflate(_padding);
    child.layout(innerConstraints, parentUsesSize: true);
    final BoxParentData childParentData = child.parentData;
    childParentData.offset = Offset(_padding.left, _padding.top);
    size = constraints.constrain(Size(
      _padding.left + child.size.width + _padding.right,
      _padding.top + child.size.height + _padding.bottom,
    ));
    heightReset();
  }

  RenderViewport _renderViewport;

  void _setComponent(RenderViewport renderViewport) =>
      this._renderViewport = renderViewport;

  RenderSliver _renderSliver;

  void _setRenderSliver(RenderSliver renderSliver) =>
      this._renderSliver = renderSliver;

  void heightReset() {
    if (_renderViewport == null || _renderSliver == null) {
      return;
    }

    var widgetsBinding = WidgetsBinding.instance;
    widgetsBinding.addPostFrameCallback((callback) {
      ScrollPositionWithSingleContext context = _renderViewport.offset;
      var paintExtent = _renderSliver.geometry.maxPaintExtent;

      double pd = 0;
      if (direction == Direction.left)
        pd = _padding.left;
      else if (direction == Direction.top)
        pd = _padding.top;
      else if (direction == Direction.right)
        pd = _padding.right;
      else
        pd = _padding.bottom;

      var space = context.viewportDimension - (paintExtent - pd);
      if ((space > 0 || pd > 0) && space != pd) {
        if (direction == Direction.left)
          _padding = EdgeInsets.only(left: space);
        else if (direction == Direction.top)
          _padding = EdgeInsets.only(top: space);
        else if (direction == Direction.right)
          _padding = EdgeInsets.only(right: space);
        else if (direction == Direction.bottom)
          _padding = EdgeInsets.only(bottom: space);
        markNeedsLayout();
      }
    });
  }
}

enum Direction { left, top, right, bottom }
