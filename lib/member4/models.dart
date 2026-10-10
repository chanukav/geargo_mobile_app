import 'package:cloud_firestore/cloud_firestore.dart';

const photoAngles = {
  'front': 'Front',
  'back': 'Back',
  'left': 'Left Side',
  'right': 'Right Side',
};
const checklistLabels = {
  'identity': 'Verify the other person’s identity with photo ID',
  'damage': 'Inspect equipment condition for major damage',
  'accessories': 'Check all accessories included',
};

class RentalRecord {
  final String id;
  final Map<String, dynamic> data;
  RentalRecord(this.id, this.data);
  factory RentalRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      RentalRecord(doc.id, doc.data()!);
  String get equipmentName => data['equipmentName'] as String;
  String get status => data['status'] as String;
  String get phase => status == 'pending' ? 'pickup' : 'return';
  String get currency => data['currency'] as String? ?? 'USD';
  String get dateLabel => '${data['startDate']} – ${data['endDate']}';
  Map<String, dynamic> get meetup =>
      Map<String, dynamic>.from(data['meetup'] as Map);
  Map<String, dynamic> get deposit =>
      Map<String, dynamic>.from(data['deposit'] as Map);
  Map<String, dynamic> condition(String phase) =>
      Map<String, dynamic>.from((data['conditions'] as Map)[phase] as Map);
  Map<String, String> photos(String phase) =>
      Map<String, String>.from(condition(phase)['photos'] as Map);
  Map<String, dynamic> checklist(String phase) =>
      Map<String, dynamic>.from((data['checklists'] as Map)[phase] as Map);
  bool get confirmedCondition => condition(phase)['status'] == 'confirmed';
  int get completedSteps =>
      checklistLabels.keys.where((k) => checklist(phase)[k] == true).length +
      (confirmedCondition ? 1 : 0);
  bool get canConfirm => completedSteps == 4 && status != 'completed';
  bool confirmedBy(String uid) =>
      ((data['confirmations'] as Map)[phase] as Map).containsKey(uid);
  String counterpart(String uid) => uid == data['ownerId']
      ? data['renterName'] as String
      : data['ownerName'] as String;
  String money(num amount) => '$currency ${amount.toStringAsFixed(2)}';
}
