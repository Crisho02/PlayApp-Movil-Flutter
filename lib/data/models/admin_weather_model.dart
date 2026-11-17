class AdminWeatherMetric {
  final String label;
  final String value;

  AdminWeatherMetric({
    required this.label,
    required this.value,
  });

  factory AdminWeatherMetric.fromJson(Map<String, dynamic> json) {
    return AdminWeatherMetric(
      label: (json['label'] ?? json['shortLabel'] ?? '').toString(),
      value: (json['value'] ?? '').toString(),
    );
  }
}

class AdminWeatherEstimate {
  final int minimum;
  final int maximum;
  final String condition;
  final String explanation;
  final String summary;

  AdminWeatherEstimate({
    required this.minimum,
    required this.maximum,
    required this.condition,
    required this.explanation,
    required this.summary,
  });

  factory AdminWeatherEstimate.fromJson(Map<String, dynamic> json) {
    return AdminWeatherEstimate(
      minimum: (json['minimum'] is num) ? (json['minimum'] as num).toInt() : 0,
      maximum: (json['maximum'] is num) ? (json['maximum'] as num).toInt() : 0,
      condition: (json['condition'] ?? '').toString(),
      explanation: (json['explanation'] ?? '').toString(),
      summary: (json['summary'] ?? '').toString(),
    );
  }
}

class AdminWeatherModel {
  final String description;
  final String observedAt;
  final String consultedAt;
  final List<AdminWeatherMetric> metrics;
  final AdminWeatherEstimate? estimate;
  final bool isNight;
  final double latitude;
  final double longitude;

  AdminWeatherModel({
    required this.description,
    required this.observedAt,
    required this.consultedAt,
    required this.metrics,
    this.estimate,
    this.isNight = false,
    this.latitude = 10.399667,
    this.longitude = -75.555001,
  });

  String get temperature {
    for (final m in metrics) {
      if (m.label.toLowerCase().contains('temperatura')) {
        return m.value;
      }
    }
    return '30 °C';
  }

  String get feelsLike {
    for (final m in metrics) {
      if (m.label.toLowerCase().contains('sensaci')) {
        return m.value;
      }
    }
    return '';
  }

  String get wind {
    for (final m in metrics) {
      if (m.label.toLowerCase() == 'viento') {
        return m.value;
      }
    }
    return '';
  }

  String get humidity {
    for (final m in metrics) {
      if (m.label.toLowerCase().contains('humedad')) {
        return m.value;
      }
    }
    return '';
  }

  String get clouds {
    for (final m in metrics) {
      if (m.label.toLowerCase().contains('nubosidad')) {
        return m.value;
      }
    }
    return '';
  }

  String get pressure {
    for (final m in metrics) {
      if (m.label.toLowerCase().contains('presi')) {
        return m.value;
      }
    }
    return '';
  }

  String get visibility {
    for (final m in metrics) {
      if (m.label.toLowerCase().contains('visibilidad')) {
        return m.value;
      }
    }
    return '';
  }

  String get sunrise {
    for (final m in metrics) {
      if (m.label.toLowerCase().contains('amanecer')) {
        final val = m.value;
        if (val.contains(' ')) {
          final parts = val.split(' ');
          if (parts.length > 1) return parts[1];
        }
        return val;
      }
    }
    return '05:58';
  }

  String get sunset {
    for (final m in metrics) {
      if (m.label.toLowerCase().contains('atardecer')) {
        final val = m.value;
        if (val.contains(' ')) {
          final parts = val.split(' ');
          if (parts.length > 1) return parts[1];
        }
        return val;
      }
    }
    return '17:36';
  }

  factory AdminWeatherModel.fromJson(Map<String, dynamic> json, {Map<String, dynamic>? location}) {
    List<AdminWeatherMetric> metricsList = [];
    if (json['metrics'] is List) {
      for (final item in json['metrics']) {
        if (item is Map<String, dynamic>) {
          metricsList.add(AdminWeatherMetric.fromJson(item));
        }
      }
    }

    AdminWeatherEstimate? est;
    if (json['estimate'] is Map<String, dynamic>) {
      est = AdminWeatherEstimate.fromJson(json['estimate'] as Map<String, dynamic>);
    }

    bool night = false;
    if (json['artwork'] is Map && (json['artwork'] as Map)['night'] == true) {
      night = true;
    }

    double lat = 10.399667;
    double lon = -75.555001;
    if (location != null) {
      if (location['latitude'] is num) lat = (location['latitude'] as num).toDouble();
      if (location['longitude'] is num) lon = (location['longitude'] as num).toDouble();
    }

    return AdminWeatherModel(
      description: (json['description'] ?? 'Cielo despejado').toString(),
      observedAt: (json['observedAt'] ?? '').toString(),
      consultedAt: (json['consultedAt'] ?? '').toString(),
      metrics: metricsList,
      estimate: est,
      isNight: night,
      latitude: lat,
      longitude: lon,
    );
  }
}
