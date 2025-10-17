import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/stabilization_provider.dart';
import '../../providers/app_settings_provider.dart';
import '../../widgets/common/stabilization_toggle.dart';
import '../../widgets/common/mode_selector.dart';
import '../../widgets/common/status_indicator.dart';

/// 메인 홈 화면
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CalmRide'),
        centerTitle: true,
        actions: [
          Consumer<AppSettingsProvider>(
            builder: (context, settingsProvider, child) {
              if (settingsProvider.settings.isProUser) {
                return Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: AppColors.proGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'PRO',
                    style: AppTextStyles.proText,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // 상태 표시기
              const StatusIndicator(),
              
              const SizedBox(height: 32),
              
              // 메인 토글 버튼
              const StabilizationToggle(),
              
              const SizedBox(height: 32),
              
              // 모드 선택기
              const ModeSelector(),
              
              const SizedBox(height: 32),
              
              // 현재 설정 정보
              const CurrentSettingsCard(),
              
              const Spacer(),
              
              // Pro 업그레이드 카드 (무료 사용자만)
              Consumer<AppSettingsProvider>(
                builder: (context, settingsProvider, child) {
                  if (!settingsProvider.settings.isProUser) {
                    return const ProUpgradeCard();
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 현재 설정 정보 카드
class CurrentSettingsCard extends StatelessWidget {
  const CurrentSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<StabilizationProvider, AppSettingsProvider>(
      builder: (context, stabilizationProvider, settingsProvider, child) {
        final settings = settingsProvider.settings;
        final mode = stabilizationProvider.currentMode;
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '현재 설정',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                _buildSettingRow(
                  context,
                  '안정화 모드',
                  mode.displayName,
                ),
                const SizedBox(height: 8),
                _buildSettingRow(
                  context,
                  '색온도',
                  '${(settings.colorTemperature * 100).round()}%',
                ),
                const SizedBox(height: 8),
                _buildSettingRow(
                  context,
                  '민감도',
                  '${(settings.dotSettings.sensitivity * 100).round()}%',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Pro 업그레이드 카드
class ProUpgradeCard extends StatelessWidget {
  const ProUpgradeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.proGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Pro로 업그레이드',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '무제한 사용, 자동화 기능, 위젯 등 모든 기능을 이용하세요!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _showProUpgradeDialog(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.proGold,
                    elevation: 0,
                  ),
                  child: const Text(
                    '9,900원에 업그레이드',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Pro 업그레이드 다이얼로그 표시
  void _showProUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.proGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.star,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Pro 업그레이드'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CalmRide Pro로 업그레이드하여 모든 기능을 이용하세요!',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            _buildFeatureItem('무제한 사용 시간'),
            _buildFeatureItem('모든 안정화 모드'),
            _buildFeatureItem('자동화 기능'),
            _buildFeatureItem('고급 통계 및 인사이트'),
            _buildFeatureItem('위젯 기능'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryMint.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_offer,
                    color: AppColors.primaryMint,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '특별 가격: 9,900원',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryMint,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('나중에'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _upgradeToPro(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.proGold,
              foregroundColor: Colors.white,
            ),
            child: const Text('업그레이드'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(feature),
        ],
      ),
    );
  }

  /// Pro로 업그레이드 처리
  void _upgradeToPro(BuildContext context) {
    // 실제 앱에서는 결제 처리 로직이 들어가야 함
    // 여기서는 데모용으로 Pro 상태를 토글
    final settingsProvider = Provider.of<AppSettingsProvider>(context, listen: false);
    settingsProvider.updateProUserStatus(true);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pro 업그레이드가 완료되었습니다! 🎉'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
