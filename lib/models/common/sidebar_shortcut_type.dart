import 'package:PiliPlus/common/widgets/custom_icon.dart';
import 'package:PiliPlus/models/common/enum_with_label.dart';
import 'package:material_ui/material_ui.dart';

enum SidebarShortcutType implements EnumWithLabel {
  messages('消息', Icons.notifications_none),
  search('搜索', Icons.search_outlined),
  history('观看记录', CustomIcons.history),
  later('稍后再看', CustomIcons.watch_later_outlined),
  favorite('我的收藏', CustomIcons.star_favorite_line);

  static const kDefault = [messages, search, history, later];

  @override
  final String label;
  final IconData icon;

  const SidebarShortcutType(this.label, this.icon);
}
