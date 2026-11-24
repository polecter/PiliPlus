import 'package:PiliPlus/common/widgets/custom_icon.dart';
import 'package:PiliPlus/models/common/enum_with_label.dart';
import 'package:material_ui/material_ui.dart';

enum MineShortcutType implements EnumWithLabel {
  favorite('我的收藏', CustomIcons.star_favorite_line),
  download('离线缓存', CustomIcons.folderDownloadOutline),
  history('观看记录', CustomIcons.history),
  subscription('我的订阅', CustomIcons.subscriptions_outlined),
  later('稍后再看', CustomIcons.watch_later_outlined);

  static const kDefault = [
    favorite,
    download,
    history,
    subscription,
    later,
  ];

  @override
  final String label;
  final IconData icon;

  const MineShortcutType(this.label, this.icon);
}
