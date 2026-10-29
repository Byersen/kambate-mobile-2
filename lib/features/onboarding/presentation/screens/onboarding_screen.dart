import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/sport_type.dart';
import '../../../../services/cache_service.dart';
import '../../../feed/providers/feed_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final List<SportType> _allSports = const [
    SportType.soccer,
    SportType.nba,
    SportType.lol,
    SportType.valorant,
    SportType.ufc,
  ];

  late final Set<SportType> _selectedSports;
  bool _isSaving = false;

  final Map<SportType, String> _sportDescriptions = const {
    SportType.soccer: 'Champions League, Premier, LaLiga, Libertadores',
    SportType.nba: 'Temporada Regular, Playoffs, Conferencia Este y Oeste',
    SportType.lol: 'Worlds, MSI, LCK, LEC, LLA Esports',
    SportType.valorant: 'VCT Champions Tour, Masters, VCT Americas',
    SportType.ufc: 'UFC PPV Numerados, Carteleras y Fight Nights',
  };

  @override
  void initState() {
    super.initState();
    final current = ref.read(selectedSportsProvider);
    _selectedSports = current.isNotEmpty
        ? Set<SportType>.from(current)
        : Set<SportType>.from(_allSports);
    _syncSavedSelection();
  }

  Future<void> _syncSavedSelection() async {
    final saved = await CacheService.getSelectedSportTypes();
    if (!mounted || saved.isEmpty) return;
    setState(() {
      _selectedSports
        ..clear()
        ..addAll(saved);
    });
  }

  void _toggleSport(SportType sport) {
    setState(() {
      if (_selectedSports.contains(sport)) {
        if (_selectedSports.length > 1) {
          _selectedSports.remove(sport);
        }
      } else {
        _selectedSports.add(sport);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedSports.length == _allSports.length) {
        _selectedSports.clear();
        _selectedSports.add(SportType.soccer);
      } else {
        _selectedSports.addAll(_allSports);
      }
    });
  }

  Future<void> _handleContinue() async {
    setState(() => _isSaving = true);
    try {
      final orderedSelection = _allSports
          .where(_selectedSports.contains)
          .toList();
      final effectiveSelection = orderedSelection.isNotEmpty
          ? orderedSelection
          : <SportType>[SportType.soccer];

      await ref
          .read(selectedSportsProvider.notifier)
          .setSelectedSports(effectiveSelection);
      await CacheService.setOnboardingCompleted(true);

      ref.read(selectedSportFilterProvider.notifier).state =
          effectiveSelection.first;

      if (mounted) {
        context.go('/feed');
      }
    } catch (_) {
      if (mounted) {
        context.go('/feed');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allSelected = _selectedSports.length == _allSports.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Text(
                          'KAMBATE',
                          style: TextStyle(
                            color: AppColors.onPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'SPORTS',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '¡Bienvenido a Kambate!',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '¿Qué deportes te apasionan?\nSelecciona tus disciplinas favoritas para personalizar tus marcadores.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.35,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Solo cargamos partidos de tus deportes elegidos para ahorrar datos y espacio.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          '${_selectedSports.length} de ${_allSports.length} seleccionados',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _toggleSelectAll,
                        child: Text(
                          allSelected ? 'Desmarcar' : 'Seleccionar Todos',
                          style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: _allSports.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final sport = _allSports[index];
                  final isSelected = _selectedSports.contains(sport);
                  final desc = _sportDescriptions[sport] ?? '';

                  return _SportSelectionCard(
                    key: ValueKey('onboarding_sport_card_${sport.id}'),
                    sport: sport,
                    description: desc,
                    isSelected: isSelected,
                    onTap: () => _toggleSport(sport),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    elevation: 4,
                    shadowColor: AppColors.primary.withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.onPrimary,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                'Continuar a Partidos',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SportSelectionCard extends StatelessWidget {
  final SportType sport;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _SportSelectionCard({
    super.key,
    required this.sport,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.14)
                    : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: 1.2,
                ),
              ),
              child: Icon(
                sport.icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          sport.displayName,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.14)
                              : AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          sport.name.toUpperCase(),
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.primaryDark
                                : AppColors.textMuted,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surfaceMuted,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: 2.0,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: AppColors.onPrimary,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
