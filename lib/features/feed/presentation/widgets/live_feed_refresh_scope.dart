import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/feed_provider.dart';

class LiveFeedRefreshScope extends ConsumerStatefulWidget {
  const LiveFeedRefreshScope({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<LiveFeedRefreshScope> createState() =>
      _LiveFeedRefreshScopeState();
}

class _LiveFeedRefreshScopeState extends ConsumerState<LiveFeedRefreshScope> {
  late final FeedNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = ref.read(feedNotifierProvider.notifier);
    _notifier.startLiveRefresh();
  }

  @override
  void dispose() {
    _notifier.stopLiveRefresh();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
