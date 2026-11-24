import 'dart:async';

import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/video.dart';
import 'package:PiliPlus/models/common/rcmd_source.dart';
import 'package:PiliPlus/pages/common/common_controller.dart'
    show RefreshImplMixin;
import 'package:PiliPlus/pages/common/common_list_controller.dart';
import 'package:PiliPlus/utils/extension/scroll_controller_ext.dart';
import 'package:PiliPlus/utils/storage_pref.dart';

class RcmdController extends CommonListController with RefreshImplMixin {
  late bool enableSaveLastData = Pref.enableSaveLastData;

  /// 可在设置页切换后立即生效，无需重启
  RcmdSource rcmdSource = Pref.rcmdSource;

  int? lastRefreshAt;
  late bool savedRcmdTip = Pref.savedRcmdTip;
  int columnCount = 1;
  int screenCapacity = 1;
  List<dynamic> _pendingVideos = [];
  List<dynamic> _nextPendingVideos = [];
  bool _reconcilePending = false;
  int _extraFetched = 0;

  // A filtered response can contain fewer videos than the requested page size.
  // Avoid making unlimited requests if the server cannot fill a row.
  static const _maxExtraPages = 12;

  @override
  bool get isEnd => false;

  @override
  void onInit() {
    super.onInit();
    page = 0;
    queryData();
  }

  Future<LoadingState> _getPage(int index) {
    return switch (rcmdSource) {
      RcmdSource.app => VideoHttp.rcmdVideoListApp(freshIdx: index),
      // 桌面端：与官方 Windows 客户端一致，每次请求 30 条
      RcmdSource.desktop => VideoHttp.rcmdVideoList(
        freshIdx: index,
        ps: 30,
        desktop: true,
      ),
      RcmdSource.web => VideoHttp.rcmdVideoList(freshIdx: index, ps: 20),
    };
  }

  @override
  Future<LoadingState> customGetData() async {
    _extraFetched = 0;
    _nextPendingVideos = [];
    final result = await _getPage(page);
    if (page != 0 ||
        !enableSaveLastData ||
        !savedRcmdTip ||
        loadingState.value is! Success || result is! Success) {
      return result;
    }
    final previous = loadingState.value.data;
    final first = result.data;
    if (previous == null || previous.isEmpty || first == null || first.isEmpty) {
      return result;
    }

    final fresh = <dynamic>[...first];
    var extraPages = 0;
    while (fresh.length < screenCapacity && extraPages < _maxExtraPages) {
      try {
        final next = await _getPage(extraPages + 1);
        if (next is! Success || next.data == null || next.data!.isEmpty) {
          break;
        }
        fresh.addAll(next.data!);
        extraPages++;
      } catch (_) {
        break;
      }
    }
    final visibleCount =
        (fresh.length < screenCapacity ? fresh.length : screenCapacity) ~/
        columnCount *
        columnCount;
    if (visibleCount == 0) {
      return const Error('推荐视频不足一行，请重试');
    }
    _nextPendingVideos = fresh.sublist(visibleCount);
    // The common list controller increments page once after this response.
    _extraFetched = extraPages;
    return Success(fresh.sublist(0, visibleCount));
  }

  bool updateLayout(int columns, int capacity) {
    if (columnCount == columns && screenCapacity == capacity) return false;
    columnCount = columns;
    screenCapacity = capacity;
    return true;
  }

  Future<void> reconcileCurrentScreen() async {
    if (!enableSaveLastData || !savedRcmdTip) return;
    if (isLoading) {
      _reconcilePending = true;
      return;
    }
    if (loadingState.value case Success(:final response)) {
      if (response == null || lastRefreshAt == null ||
          lastRefreshAt! < 0 ||
          lastRefreshAt! > response.length) {
        return;
      }
      final boundary = lastRefreshAt!;
      if (boundary == screenCapacity) return;
      isLoading = true;
      try {
        final available = <dynamic>[
          ...response.take(boundary),
          ..._pendingVideos,
        ];
        var extraPages = 0;
        while (available.length < screenCapacity &&
            extraPages < _maxExtraPages) {
          try {
            final next = await _getPage(page);
            if (next is! Success || next.data == null || next.data!.isEmpty) {
              break;
            }
            available.addAll(next.data!);
            page++;
            extraPages++;
          } catch (_) {
            break;
          }
        }
        final count =
            (available.length < screenCapacity
                ? available.length
                : screenCapacity) ~/
            columnCount *
            columnCount;
        if (count == 0) return;
        response.replaceRange(0, boundary, available.take(count));
        _pendingVideos = available.sublist(count);
        lastRefreshAt = count;
        loadingState.refresh();
      } catch (_) {
        // Keep the continuous grid if the server cannot supply another page.
      } finally {
        isLoading = false;
        if (_reconcilePending) {
          _reconcilePending = false;
          unawaited(reconcileCurrentScreen());
        }
      }
    }
  }

  @override
  Future<void> queryData([bool isRefresh = true]) async {
    if (isLoading) return;
    if (!isRefresh && _pendingVideos.isNotEmpty) {
      if (loadingState.value case Success(:final response?)) {
        response.addAll(_pendingVideos);
        _pendingVideos = [];
        loadingState.refresh();
        return;
      }
    }
    await super.queryData(isRefresh);
    page += _extraFetched;
    _extraFetched = 0;
    if (_reconcilePending) {
      _reconcilePending = false;
      await reconcileCurrentScreen();
    }
  }

  @override
  bool handleError(String? errMsg) {
    return enableSaveLastData;
  }

  @override
  void handleListResponse(List dataList) {
    if (page == 0) {
      final previousPending = _pendingVideos;
      _pendingVideos = _nextPendingVideos;
      _nextPendingVideos = [];
      if (!enableSaveLastData) {
        _pendingVideos = [];
        lastRefreshAt = null;
        return;
      }
      if (loadingState.value case Success(:final response)) {
        if (response != null && response.isNotEmpty) {
          if (savedRcmdTip) {
            lastRefreshAt = dataList.length;
          }
          if (response.length > 200) {
            dataList.addAll(response.take(50));
          } else {
            dataList.addAll(response);
          }
          dataList.addAll(previousPending);
        }
      }
    }
  }

  @override
  Future<void> onRefresh() {
    if (isLoading) return Future.value();
    page = 0;
    isEnd = false;
    return queryData();
  }

  void toTopAndRefresh() {
    scrollController.jumpToTop();
    showRefresh();
  }
}
