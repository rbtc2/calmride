import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/sensors/sensor_manager.dart';
import '../core/sensors/sensor_permission_manager.dart';
import '../core/sensors/accelerometer_processor.dart';

/// 센서 상태를 관리하는 Provider
class SensorProvider extends ChangeNotifier {
  final SensorManager _sensorManager = SensorManager();
  final SensorPermissionManager _permissionManager = SensorPermissionManager();
  final AccelerometerProcessor _accelerometerProcessor = AccelerometerProcessor();
  
  // 센서 상태
  bool _isInitialized = false;
  bool _isActive = false;
  String _errorMessage = '';
  
  // 센서 데이터
  SensorData? _lastAccelerometerData;
  SensorData? _lastGyroscopeData;
  
  // 가속도계 처리 상태
  bool get isAccelerometerMoving => _accelerometerProcessor.isMoving;
  double get accelerometerMovementIntensity => _accelerometerProcessor.movementIntensity;
  VehicleMovementDirection get vehicleMovementDirection => _accelerometerProcessor.getVehicleMovementDirection();
  
  // 권한 상태
  Map<Permission, PermissionStatus> _permissionStatuses = {};

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isActive => _isActive;
  String get errorMessage => _errorMessage;
  SensorData? get lastAccelerometerData => _lastAccelerometerData;
  SensorData? get lastGyroscopeData => _lastGyroscopeData;
  Map<Permission, PermissionStatus> get permissionStatuses => _permissionStatuses;
  
  bool get areSensorsAvailable => _sensorManager.areSensorsAvailable;
  bool get arePermissionsGranted => _permissionStatuses.values.every((status) => 
    status == PermissionStatus.granted || status == PermissionStatus.limited);

  // 센서 스트림 접근자
  Stream<SensorData>? get accelerometerStream => _sensorManager.accelerometerStream;
  Stream<SensorData>? get gyroscopeStream => _sensorManager.gyroscopeStream;

  /// 센서 시스템 초기화
  Future<bool> initialize() async {
    try {
      _errorMessage = '';
      
      // 권한 확인
      _permissionStatuses = await _permissionManager.checkAllPermissions();
      
      // 센서 초기화
      final sensorInitialized = await _sensorManager.initialize();
      
      if (!sensorInitialized) {
        _errorMessage = '센서를 사용할 수 없습니다.';
        return false;
      }
      
      _isInitialized = true;
      notifyListeners();
      
      debugPrint('센서 시스템 초기화 완료');
      return true;
    } catch (e) {
      _errorMessage = '센서 초기화 실패: $e';
      debugPrint(_errorMessage);
      return false;
    }
  }

  /// 권한 요청
  Future<bool> requestPermissions(BuildContext context) async {
    try {
      final shouldRequest = await _permissionManager.showPermissionDialog(context);
      if (!shouldRequest) return false;
      
      _permissionStatuses = await _permissionManager.requestPermissions();
      notifyListeners();
      
      return arePermissionsGranted;
    } catch (e) {
      _errorMessage = '권한 요청 실패: $e';
      debugPrint(_errorMessage);
      return false;
    }
  }

  /// 센서 스트림 시작
  Future<bool> startSensors() async {
    if (!_isInitialized) {
      _errorMessage = '센서가 초기화되지 않았습니다.';
      return false;
    }
    
    if (!arePermissionsGranted) {
      _errorMessage = '필요한 권한이 허용되지 않았습니다.';
      return false;
    }

    try {
      _errorMessage = '';
      
      // 센서 스트림 시작
      final success = await _sensorManager.startAllSensors();
      
      if (success) {
        _isActive = true;
        
        // 센서 데이터 스트림 구독
        _subscribeToSensorStreams();
        
        debugPrint('센서 스트림 시작 완료');
        notifyListeners();
        return true;
      } else {
        _errorMessage = '센서 스트림 시작 실패';
        return false;
      }
    } catch (e) {
      _errorMessage = '센서 시작 실패: $e';
      debugPrint(_errorMessage);
      return false;
    }
  }

  /// 센서 스트림 중지
  void stopSensors() {
    try {
      _sensorManager.stopAllSensors();
      _isActive = false;
      _errorMessage = '';
      
      debugPrint('센서 스트림 중지 완료');
      notifyListeners();
    } catch (e) {
      _errorMessage = '센서 중지 실패: $e';
      debugPrint(_errorMessage);
    }
  }

  /// 센서 데이터 스트림 구독
  void _subscribeToSensorStreams() {
    // 가속도계 데이터 구독
    _sensorManager.accelerometerStream?.listen(
      (data) {
        _lastAccelerometerData = data;
        _accelerometerProcessor.processAccelerometerData(data);
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = '가속도계 오류: $error';
        debugPrint(_errorMessage);
        notifyListeners();
      },
    );

    // 자이로스코프 데이터 구독
    _sensorManager.gyroscopeStream?.listen(
      (data) {
        _lastGyroscopeData = data;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = '자이로스코프 오류: $error';
        debugPrint(_errorMessage);
        notifyListeners();
      },
    );
  }

  /// 센서 상태 정보 가져오기
  Map<String, dynamic> getSensorStatus() {
    return {
      'isInitialized': _isInitialized,
      'isActive': _isActive,
      'areSensorsAvailable': areSensorsAvailable,
      'arePermissionsGranted': arePermissionsGranted,
      'accelerometerStatus': _sensorManager.accelerometerStatus.displayName,
      'gyroscopeStatus': _sensorManager.gyroscopeStatus.displayName,
      'errorMessage': _errorMessage,
      'lastAccelerometerData': _lastAccelerometerData?.toString(),
      'lastGyroscopeData': _lastGyroscopeData?.toString(),
    };
  }

  /// 권한 설정으로 이동
  Future<void> openAppSettings() async {
    await _permissionManager.openAppSettings();
  }

  @override
  void dispose() {
    _sensorManager.dispose();
    super.dispose();
  }
}
