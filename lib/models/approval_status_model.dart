class ApprovalStatusResponse {
  final bool success;
  final ApprovalStatusData data;

  ApprovalStatusResponse({
    required this.success,
    required this.data,
  });

  factory ApprovalStatusResponse.fromJson(Map<String, dynamic> json) {
    return ApprovalStatusResponse(
      success: json['success'],
      data: ApprovalStatusData.fromJson(json['data']),
    );
  }
}

class ApprovalStatusData {
  final String driverId;
  final String driverName;
  final String status; // "pending_approval", "under_review", "approved", "rejected"
  final bool canLogin;
  final List<TimelineStep> timeline;
  final DocumentStatistics statistics;

  ApprovalStatusData({
    required this.driverId,
    required this.driverName,
    required this.status,
    required this.canLogin,
    required this.timeline,
    required this.statistics,
  });

  factory ApprovalStatusData.fromJson(Map<String, dynamic> json) {
    return ApprovalStatusData(
      driverId: json['driverId'],
      driverName: json['driverName'],
      status: json['status'],
      canLogin: json['canLogin'],
      timeline: (json['timeline'] as List)
          .map((item) => TimelineStep.fromJson(item))
          .toList(),
      statistics: DocumentStatistics.fromJson(json['statistics']),
    );
  }
}

class TimelineStep {
  final String step; // "registration", "data_review", "document_review", "approved"
  final String title;
  final String description;
  final String status; // "completed", "in_progress", "pending", "rejected"
  final String? date;

  TimelineStep({
    required this.step,
    required this.title,
    required this.description,
    required this.status,
    this.date,
  });

  factory TimelineStep.fromJson(Map<String, dynamic> json) {
    return TimelineStep(
      step: json['step'],
      title: json['title'],
      description: json['description'],
      status: json['status'],
      date: json['date'],
    );
  }
}

class DocumentStatistics {
  final int totalDocuments;
  final int uploadedDocuments;
  final int approvedDocuments;
  final int rejectedDocuments;
  final int pendingDocuments;

  DocumentStatistics({
    required this.totalDocuments,
    required this.uploadedDocuments,
    required this.approvedDocuments,
    required this.rejectedDocuments,
    required this.pendingDocuments,
  });

  factory DocumentStatistics.fromJson(Map<String, dynamic> json) {
    return DocumentStatistics(
      totalDocuments: json['totalDocuments'],
      uploadedDocuments: json['uploadedDocuments'],
      approvedDocuments: json['approvedDocuments'],
      rejectedDocuments: json['rejectedDocuments'],
      pendingDocuments: json['pendingDocuments'],
    );
  }
}
