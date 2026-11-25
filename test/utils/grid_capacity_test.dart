import 'package:PiliPlus/utils/grid.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

SliverConstraints _constraints(double width, double height) =>
    SliverConstraints(
      axisDirection: AxisDirection.down,
      growthDirection: GrowthDirection.forward,
      userScrollDirection: ScrollDirection.idle,
      scrollOffset: 0,
      precedingScrollExtent: 0,
      overlap: 0,
      remainingPaintExtent: height,
      crossAxisExtent: width,
      crossAxisDirection: AxisDirection.right,
      viewportMainAxisExtent: height,
      remainingCacheExtent: height,
      cacheOrigin: 0,
    );

void main() {
  test('refresh capacity includes partially visible rows at each card width', () {
    SliverGridDelegateWithExtentAndRatio delegate(double maxWidth) =>
        SliverGridDelegateWithExtentAndRatio(
          maxCrossAxisExtent: maxWidth,
          childAspectRatio: 1.6,
          mainAxisExtent: 90,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        );

    final constraints = _constraints(1150, 850);
    final wideCards = delegate(300);
    final defaultCards = delegate(240);

    expect(wideCards.crossAxisCountFor(1150), 4);
    expect(wideCards.visibleItemCountFor(constraints, topPadding: 8), 16);
    expect(defaultCards.crossAxisCountFor(1150), 5);
    expect(defaultCards.visibleItemCountFor(constraints, topPadding: 8), 20);
    expect(
      defaultCards.visibleItemCountFor(_constraints(1150, 560), topPadding: 8),
      15,
    );
    expect(
      wideCards.visibleItemCountFor(_constraints(1150, 560), topPadding: 8),
      12,
    );
    expect(
      wideCards.visibleItemCountFor(_constraints(1150, 460), topPadding: 8),
      8,
    );
  });
}
