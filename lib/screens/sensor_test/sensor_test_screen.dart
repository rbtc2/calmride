import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sensor_provider.dart';
import '../../widgets/sensors/accelerometer_monitor.dart';
import '../../widgets/sensors/gyroscope_monitor.dart';
import '../../widgets/sensors/integrated_sensor_monitor.dart';
import '../../widgets/sensors/sensor_data_chart.dart';
import '../../widgets/sensors/sensor_performance_stats.dart';
import '../../widgets/sensors/filter_settings_widget.dart';
import '../../widgets/sensors/filter_performance_monitor.dart';
import '../../core/sensors/sensor_data_filter.dart';

/// 센서 테스트 화면
class SensorTestScreen extends StatefulWidget {
  const SensorTestScreen({super.key});

  @override
  State<SensorTestScreen> createState() => _SensorTestScreenState();
}

class _SensorTestScreenState extends State<SensorTestScreen> {
  bool _isLoggingEnabled = false;
  final List<String> _logMessages = [];
  static const int maxLogMessages = 50;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('센서 테스트'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isLoggingEnabled ? Icons.stop : Icons.play_arrow),
            onPressed: _toggleLogging,
            tooltip: _isLoggingEnabled ? '로깅 중지' : '로깅 시작',
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearLogs,
            tooltip: '로그 지우기',
          ),
        ],
      ),
      body: Consumer<SensorProvider>(
        builder: (context, sensorProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 센서 상태 카드
                _buildSensorStatusCard(sensorProvider),
                
                const SizedBox(height: 16),
                
                // 센서 제어 버튼들
                _buildControlButtons(sensorProvider),
                
                const SizedBox(height: 16),
                
                // 센서 모니터들
                if (sensorProvider.isActive) ...[
                  FilterSettingsWidget(
                    initialSettings: const FilterSettings(),
                    onSettingsChanged: _onFilterSettingsChanged,
                  ),
                  const SizedBox(height: 16),
                  FilterPerformanceMonitor(
                    accelerometerPerformance: sensorProvider.getAccelerometerFilterPerformance(),
                    gyroscopePerformance: sensorProvider.getGyroscopeFilterPerformance(),
                  ),
                  const SizedBox(height: 16),
                  const SensorDataChart(),
                  const SizedBox(height: 16),
                  const SensorPerformanceStats(),
                  const SizedBox(height: 16),
                  const IntegratedSensorMonitor(),
                  const SizedBox(height: 16),
                  const AccelerometerMonitor(),
                  const SizedBox(height: 16),
                  const GyroscopeMonitor(),
                  const SizedBox(height: 16),
                ],
                
                // 실시간 로그
                _buildLogSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 센서 상태 카드
  Widget _buildSensorStatusCard(SensorProvider sensorProvider) {
    final status = sensorProvider.getSensorStatus();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '센서 상태',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            // 상태 정보들
            _buildStatusRow('초기화 상태', status['isInitialized'] ? '완료' : '미완료'),
            _buildStatusRow('센서 활성화', status['isActive'] ? '활성' : '비활성'),
            _buildStatusRow('센서 사용 가능', status['areSensorsAvailable'] ? '가능' : '불가능'),
            _buildStatusRow('권한 허용', status['arePermissionsGranted'] ? '허용' : '거부'),
            _buildStatusRow('가속도계 상태', status['accelerometerStatus']),
            _buildStatusRow('자이로스코프 상태', status['gyroscopeStatus']),
            _buildStatusRow('스트림 통합', sensorProvider.isStreamIntegrationActive ? '활성' : '비활성'),
            _buildStatusRow('통합 데이터 수', sensorProvider.integratedDataHistory.length.toString()),
            _buildStatusRow('필터링 활성', sensorProvider.isFilteringActive ? '활성' : '비활성'),
            _buildStatusRow('필터 오류', sensorProvider.filteringError.isEmpty ? '없음' : '있음'),
            
            if (status['errorMessage'].isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '오류: ${status['errorMessage']}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 상태 행 위젯
  Widget _buildStatusRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(value).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value.toString(),
              style: TextStyle(
                color: _getStatusColor(value),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 상태에 따른 색상 반환
  Color _getStatusColor(dynamic value) {
    if (value is bool) {
      return value ? Colors.green : Colors.red;
    }
    
    final strValue = value.toString().toLowerCase();
    if (strValue.contains('완료') || strValue.contains('활성') || 
        strValue.contains('가능') || strValue.contains('허용')) {
      return Colors.green;
    } else if (strValue.contains('미완료') || strValue.contains('비활성') || 
               strValue.contains('불가능') || strValue.contains('거부')) {
      return Colors.red;
    } else if (strValue.contains('오류')) {
      return Colors.orange;
    }
    
    return Colors.blue;
  }

  /// 센서 제어 버튼들
  Widget _buildControlButtons(SensorProvider sensorProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '센서 제어',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: sensorProvider.isInitialized 
                        ? null 
                        : () => _initializeSensors(sensorProvider),
                    icon: const Icon(Icons.settings),
                    label: const Text('초기화'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: !sensorProvider.isInitialized || sensorProvider.isActive
                        ? null 
                        : () => _startSensors(sensorProvider),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('시작'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: !sensorProvider.isActive
                        ? null 
                        : () => _stopSensors(sensorProvider),
                    icon: const Icon(Icons.stop),
                    label: const Text('중지'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _requestPermissions(sensorProvider),
                    icon: const Icon(Icons.security),
                    label: const Text('권한 요청'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 로그 섹션
  Widget _buildLogSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '실시간 로그',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isLoggingEnabled ? Colors.green : Colors.grey,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _isLoggingEnabled ? '로깅 중' : '로깅 중지',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: _logMessages.isEmpty
                  ? const Center(
                      child: Text(
                        '로그 메시지가 없습니다.\n로깅을 시작하세요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _logMessages.length,
                      itemBuilder: (context, index) {
                        final message = _logMessages[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            message,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// 센서 초기화
  Future<void> _initializeSensors(SensorProvider sensorProvider) async {
    _addLog('센서 초기화 시작...');
    
    final success = await sensorProvider.initialize();
    
    if (success) {
      _addLog('✅ 센서 초기화 완료');
    } else {
      _addLog('❌ 센서 초기화 실패: ${sensorProvider.errorMessage}');
    }
  }

  /// 센서 시작
  Future<void> _startSensors(SensorProvider sensorProvider) async {
    _addLog('센서 스트림 시작...');
    
    final success = await sensorProvider.startSensors();
    
    if (success) {
      _addLog('✅ 센서 스트림 시작 완료');
      
      // 센서 데이터 스트림 구독
      _subscribeToSensorData(sensorProvider);
    } else {
      _addLog('❌ 센서 스트림 시작 실패: ${sensorProvider.errorMessage}');
    }
  }

  /// 센서 중지
  void _stopSensors(SensorProvider sensorProvider) {
    sensorProvider.stopSensors();
    _addLog('⏹️ 센서 스트림 중지');
  }

  /// 권한 요청
  Future<void> _requestPermissions(SensorProvider sensorProvider) async {
    _addLog('권한 요청 시작...');
    
    final success = await sensorProvider.requestPermissions(context);
    
    if (success) {
      _addLog('✅ 권한 요청 완료');
    } else {
      _addLog('❌ 권한 요청 실패: ${sensorProvider.errorMessage}');
    }
  }

  /// 센서 데이터 스트림 구독
  void _subscribeToSensorData(SensorProvider sensorProvider) {
    // 가속도계 데이터 구독
    sensorProvider.accelerometerStream?.listen(
      (data) {
        if (_isLoggingEnabled) {
          _addLog('📱 가속도계: X=${data.x.toStringAsFixed(3)}, Y=${data.y.toStringAsFixed(3)}, Z=${data.z.toStringAsFixed(3)}');
        }
      },
    );

    // 자이로스코프 데이터 구독
    sensorProvider.gyroscopeStream?.listen(
      (data) {
        if (_isLoggingEnabled) {
          _addLog('🔄 자이로스코프: X=${data.x.toStringAsFixed(3)}, Y=${data.y.toStringAsFixed(3)}, Z=${data.z.toStringAsFixed(3)}');
        }
      },
    );

    // 통합 센서 데이터 구독
    sensorProvider.integratedStream?.listen(
      (data) {
        if (_isLoggingEnabled) {
          _addLog('🔗 통합센서: 강도=${(data.combinedMotionIntensity * 100).round()}%, 상태=${data.motionState.displayName}, 품질=${data.motionQuality.displayName}');
        }
      },
    );
  }

  /// 로깅 토글
  void _toggleLogging() {
    setState(() {
      _isLoggingEnabled = !_isLoggingEnabled;
    });
    
    if (_isLoggingEnabled) {
      _addLog('📝 로깅 시작');
    } else {
      _addLog('📝 로깅 중지');
    }
  }

  /// 로그 지우기
  void _clearLogs() {
    setState(() {
      _logMessages.clear();
    });
  }

  /// 로그 메시지 추가
  void _addLog(String message) {
    if (!mounted) return;
    
    setState(() {
      final timestamp = DateTime.now().toIso8601String().substring(11, 19);
      _logMessages.add('[$timestamp] $message');
      
      // 최대 로그 메시지 수 제한
      if (_logMessages.length > maxLogMessages) {
        _logMessages.removeAt(0);
      }
    });
  }

  /// 필터 설정 변경 콜백
  void _onFilterSettingsChanged(FilterSettings settings) {
    final sensorProvider = Provider.of<SensorProvider>(context, listen: false);
    sensorProvider.updateFilterSettings(settings);
    _addLog('🔧 필터 설정 업데이트: ${settings.toString()}');
  }
}
