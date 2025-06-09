import 'audit_sheet.dart';


class AuditSubmission {
  String? submissionId;
  String? submittedAt;
  String? submittedBy;
  int? totalScore;
  String? percentage;
  List<Responses>? responses;

  AuditSubmission(
      {this.submissionId,
        this.submittedAt,
        this.submittedBy,
        this.totalScore,
        this.percentage,
        this.responses});

  AuditSubmission.fromJson(Map<String, dynamic> json) {
    submissionId = json['submissionId'];
    submittedAt = json['submittedAt'];
    submittedBy = json['submittedBy'];
    totalScore = json['totalScore'];
    percentage = json['percentage'];
    if (json['responses'] != null) {
      responses = <Responses>[];
      json['responses'].forEach((v) {
        responses!.add(new Responses.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['submissionId'] = this.submissionId;
    data['submittedAt'] = this.submittedAt;
    data['submittedBy'] = this.submittedBy;
    data['totalScore'] = this.totalScore;
    data['percentage'] = this.percentage;
    if (this.responses != null) {
      data['responses'] = this.responses!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Responses {
  String? questionId;
  String? question;
  int? score;
  String? remarks;
  List<Photos>? photos;

  Responses(
      {this.questionId, this.question, this.score, this.remarks, this.photos});

  Responses.fromJson(Map<String, dynamic> json) {
    questionId = json['questionId'];
    question = json['question'];
    score = json['score'];
    remarks = json['remarks'];
    if (json['photos'] != null) {
      photos = <Photos>[];
      json['photos'].forEach((v) {
        photos!.add(new Photos.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['questionId'] = this.questionId;
    data['question'] = this.question;
    data['score'] = this.score;
    data['remarks'] = this.remarks;
    if (this.photos != null) {
      data['photos'] = this.photos!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Photos {
  String? url;
  String? description;

  Photos({this.url, this.description});

  Photos.fromJson(Map<String, dynamic> json) {
    url = json['url'];
    description = json['description'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['url'] = this.url;
    data['description'] = this.description;
    return data;
  }
}
