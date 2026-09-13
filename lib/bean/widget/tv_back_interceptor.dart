/// TV 返回键拦截链：页面在 [register] 注册回调， TvAppShell 的原生
/// "back" 通道在调用 maybePop 前先走 [handle]——回调返回 true 表示已消费
/// （例如把焦点移回分类边栏），返回 false 则继续正常的路由弹出。
class TvBackInterceptor {
  TvBackInterceptor._();

  static final List<bool Function()> _handlers = [];

  static void register(bool Function() handler) => _handlers.add(handler);

  static void unregister(bool Function() handler) => _handlers.remove(handler);

  static bool handle() {
    for (final handler in _handlers.reversed) {
      if (handler()) return true;
    }
    return false;
  }
}
