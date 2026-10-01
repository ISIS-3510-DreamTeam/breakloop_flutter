import 'package:flutter/material.dart';
import '../viewmodel/statistics_viewmodel.dart';

class DeepStatsPage extends StatefulWidget {
  const DeepStatsPage({super.key});

  @override
  State<DeepStatsPage> createState() => _DeepStatsPageState();
}

class _DeepStatsPageState extends State<DeepStatsPage> {
  late final StatisticsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = StatisticsViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color borderColor = Color(0xFF3D2314);
    const Color cardBgColor = Color(0xFFFFFBF7);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF5EF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 100,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0, top: 8.0, bottom: 8.0),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: cardBgColor,
              side: const BorderSide(color: borderColor, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.maybePop(context),
            child: const Text(
              '← Back',
              style: TextStyle(
                color: borderColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: const Text(
          'Detailed Statistics',
          style: TextStyle(
            color: borderColor,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // TARJETA 1: Mindful Unlock Intentionality
                _buildRetroCard(
                  borderColor: borderColor,
                  bgColor: cardBgColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MINDFUL UNLOCK INTENTIONALITY',
                        style: TextStyle(
                          color: Color(0xFFC86D3B),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFC86D3B),
                                width: 4,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                '84%',
                                style: TextStyle(
                                  color: Color(0xFFC86D3B),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  '84% intentional unlocks',
                                  style: TextStyle(
                                    color: borderColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Only 16% were impulsive reflex pick-ups.',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // TARJETA 2: Daily Pickup Count
                _buildRetroCard(
                  borderColor: borderColor,
                  bgColor: cardBgColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DAILY PICKUP COUNT',
                        style: TextStyle(
                          color: Color(0xFFC86D3B),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${_viewModel.dailyPickups}',
                            style: const TextStyle(
                              color: borderColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 42,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'pickups',
                            style: TextStyle(
                              color: borderColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            '-18 vs baseline',
                            style: TextStyle(
                              color: Color(0xFF2A8B78),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Average interval between phone checks: ${_viewModel.avgIntervalMinutes} minutes.',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRetroCard({
    required Widget child,
    required Color borderColor,
    required Color bgColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}