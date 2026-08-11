import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';

class DateFilterCarousel extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final Set<String> daysWithEvents;

  const DateFilterCarousel({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.daysWithEvents = const {},
  });

  @override
  State<DateFilterCarousel> createState() => _DateFilterCarouselState();
}

class _DateFilterCarouselState extends State<DateFilterCarousel> {
  late final ScrollController _scrollController;
  late final List<DateTime> _dates;
  static const int _daysBefore = 180;
  static const int _daysAfter = 180;
  static const double _itemWidth = 72.0;
  static const double _itemMargin = 6.0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    _dates = List.generate(_daysBefore + _daysAfter + 1, (index) {
      final offset = index - _daysBefore;
      return today.add(Duration(days: offset));
    });

    _scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDate(animate: false);
    });
  }

  void _scrollToSelectedDate({bool animate = true}) {
    if (!_scrollController.hasClients) return;

    final targetIndex = _dates.indexWhere(
      (d) => AppDateFormatter.isSameDay(d, widget.selectedDate),
    );

    if (targetIndex != -1) {
      final offset = (targetIndex * (_itemWidth + _itemMargin)) - 16;
      final clampedOffset = offset.clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );

      if (animate) {
        _scrollController.animateTo(
          clampedOffset,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollController.jumpTo(clampedOffset);
      }
    }
  }

  @override
  void didUpdateWidget(covariant DateFilterCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!AppDateFormatter.isSameDay(oldWidget.selectedDate, widget.selectedDate)) {
      _scrollToSelectedDate(animate: true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _dates.length,
        itemBuilder: (context, index) {
          final date = _dates[index];
          final isSelected = AppDateFormatter.isSameDay(date, widget.selectedDate);
          final relativeName = AppDateFormatter.getRelativeDayName(date);
          final shortDate = AppDateFormatter.formatShortDayMonth(date);
          final dateKey =
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          final hasEvents = widget.daysWithEvents.contains(dateKey);

          return Padding(
            padding: const EdgeInsets.only(right: _itemMargin),
            child: _CompactDateCard(
              width: _itemWidth,
              relativeName: relativeName,
              shortDate: shortDate,
              isSelected: isSelected,
              hasEvents: hasEvents,
              onTap: () {
                widget.onDateSelected(date);
              },
            ),
          );
        },
      ),
    );
  }
}

class _CompactDateCard extends StatelessWidget {
  final double width;
  final String relativeName;
  final String shortDate;
  final bool isSelected;
  final bool hasEvents;
  final VoidCallback onTap;

  const _CompactDateCard({
    required this.width,
    required this.relativeName,
    required this.shortDate,
    required this.isSelected,
    required this.hasEvents,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = relativeName == 'Hoy';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isToday
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : AppColors.cardBorderDark),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    relativeName.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      letterSpacing: 0.4,
                      color: isSelected
                          ? Colors.black
                          : (isToday ? AppColors.primary : AppColors.textPrimary),
                    ),
                  ),
                ),
                if (hasEvents && !isSelected) ...[
                  const SizedBox(width: 3),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              shortDate,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                height: 1.1,
                color: isSelected ? Colors.black.withValues(alpha: 0.85) : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
