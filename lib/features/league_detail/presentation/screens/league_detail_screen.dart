import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/sport_type.dart';
import '../../../feed/providers/feed_provider.dart';
import '../../../feed/presentation/widgets/match_card.dart';

class LeagueDetailScreen extends ConsumerStatefulWidget {
  final String leagueName;
  final SportType sport;

  const LeagueDetailScreen({
    super.key,
    required this.leagueName,
    this.sport = SportType.soccer, // Default if not passed
  });

  @override
  ConsumerState<LeagueDetailScreen> createState() => _LeagueDetailScreenState();
}

class _LeagueDetailScreenState extends ConsumerState<LeagueDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              backgroundColor: AppColors.surfaceDark,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
                onPressed: () => context.pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 48, bottom: 16, right: 16),
                title: Text(
                  widget.leagueName.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            widget.sport.color.withValues(alpha: 0.3),
                            AppColors.surfaceDark,
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: -20,
                      top: 40,
                      child: Icon(
                        widget.sport.icon,
                        size: 150,
                        color: widget.sport.color.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: widget.sport.color,
                labelColor: widget.sport.color,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: 'Partidos'),
                  Tab(text: 'Tabla'),
                  Tab(text: 'Estadísticas'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildMatchesTab(),
            _buildStandingsTab(),
            _buildStatsTab(),
          ],
        ),
      ),
    );
  }

  String _getPrettyLeagueName(String league) {
    final l = league.toLowerCase();
    
    if (l.contains('mex') || l.contains('mx')) return 'Liga MX';
    if (l.contains('usa') || l.contains('mls') || l.contains('major league')) return 'MLS';
    
    if (l.contains('copa argentina')) return 'Copa Argentina';
    if (l.contains('copa de la liga')) return 'Copa de la Liga';
    if (l.contains('arg') || l.contains('argentin') || l.contains('liga prof')) return 'Liga Profesional';
    
    if (l.contains('copa do brasil')) return 'Copa do Brasil';
    if (l.contains('bra') || l.contains('brazilian') || l.contains('brasileir')) return 'Brasileirão';
    
    if (l.contains('copa chile')) return 'Copa Chile';
    if (l.contains('chi') || l.contains('chile') || l.contains('campeonato itaú')) return 'Primera División';
    
    if (l.contains('col') || l.contains('colombia')) return 'Primera A';
    
    if (l.contains('libertadores')) return 'Copa Libertadores';
    if (l.contains('sudamericana')) return 'Copa Sudamericana';
    if (l.contains('recopa')) return 'Recopa Sudamericana';
    
    if (l.contains('champions')) return 'Champions League';
    if (l.contains('europa league') || (l.contains('europa') && !l.contains('eurocopa'))) return 'Europa League';
    if (l.contains('conference')) return 'Conference League';
    if (l.contains('supercopa de europa')) return 'Supercopa de Europa';
    
    if (l.contains('esp') || l.contains('spanish') || l.contains('laliga')) return 'LaLiga';
    if (l.contains('eng') || l.contains('english') || l.contains('premier')) return 'Premier League';
    if (l.contains('ita') || l.contains('italian') || l.contains('serie a')) return 'Serie A';
    if (l.contains('ger') || l.contains('german') || l.contains('bundesliga')) return 'Bundesliga';
    if (l.contains('fra') || l.contains('french') || l.contains('ligue 1')) return 'Ligue 1';
    if (l.contains('ned') || l.contains('dutch') || l.contains('eredivisie')) return 'Eredivisie';
    if (l.contains('por') || l.contains('portuguese') || l.contains('primeira')) return 'Primeira Liga';
    if (l.contains('tur') || l.contains('turkish') || l.contains('süper') || l.contains('super')) return 'Süper Lig';
    
    if (l.contains('fifa') || l.contains('world cup') || l.contains('mundial')) return 'Copa Mundial';
    if (l.contains('copa américa')) return 'Copa América';
    if (l.contains('eurocopa') || (l.contains('uefa') && l.contains('euro'))) return 'Eurocopa';

    return league.toUpperCase();
  }

  Widget _buildMatchesTab() {
    final feedAsync = ref.watch(feedNotifierProvider);
    return feedAsync.when(
      data: (events) {
        final leagueEvents = events.where((e) {
          // Normalize the event league name
          final eventLeague = _getPrettyLeagueName(e.league).toLowerCase();
          final targetLeague = widget.leagueName.toLowerCase();
          return eventLeague == targetLeague || eventLeague.contains(targetLeague) || targetLeague.contains(eventLeague);
        }).toList();
        
        if (leagueEvents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today_rounded, size: 48, color: AppColors.textMuted.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                const Text('No hay partidos programados', style: TextStyle(color: AppColors.textMuted)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: leagueEvents.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: MatchCard(event: leagueEvents[index]),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Error al cargar partidos')),
    );
  }

  Widget _buildStandingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorderDark),
          ),
          child: Column(
            children: [
              _buildStandingsHeader(),
              _buildStandingsRow(1, 'Equipo A', 10, 25, true),
              _buildStandingsRow(2, 'Equipo B', 10, 22, true),
              _buildStandingsRow(3, 'Equipo C', 10, 18, false),
              _buildStandingsRow(4, 'Equipo D', 10, 15, false),
              _buildStandingsRow(5, 'Equipo E', 10, 12, false),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Nota: Datos de demostración. La tabla se actualizará automáticamente.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _buildStandingsHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.cardBorderDark)),
      ),
      child: const Row(
        children: [
          SizedBox(width: 24, child: Text('#', style: TextStyle(color: AppColors.textMuted, fontSize: 12))),
          Expanded(child: Text('EQUIPO', style: TextStyle(color: AppColors.textMuted, fontSize: 12))),
          SizedBox(width: 32, child: Text('PJ', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted, fontSize: 12))),
          SizedBox(width: 32, child: Text('PTS', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildStandingsRow(int pos, String name, int pj, int pts, bool isPromotion) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.cardBorderDark)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24, 
            child: Text('$pos', style: TextStyle(color: isPromotion ? widget.sport.color : AppColors.textSecondary, fontWeight: FontWeight.bold))
          ),
          Expanded(
            child: Text(name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
          ),
          SizedBox(width: 32, child: Text('$pj', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary))),
          SizedBox(width: 32, child: Text('$pts', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('GOLEADORES', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorderDark),
          ),
          child: Column(
            children: [
              _buildStatRow(1, 'Jugador 1', 'Equipo A', 12),
              _buildStatRow(2, 'Jugador 2', 'Equipo B', 9),
              _buildStatRow(3, 'Jugador 3', 'Equipo C', 8),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(int pos, String name, String team, int goals) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.cardBorderDark)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24, 
            child: Text('$pos', style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold))
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                Text(team, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Text('$goals G', style: TextStyle(color: widget.sport.color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
