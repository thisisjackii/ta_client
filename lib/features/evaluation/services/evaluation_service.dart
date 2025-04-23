import 'package:ta_client/features/evaluation/models/evaluation.dart';
import 'package:ta_client/features/evaluation/models/history.dart';

class EvaluationService {
  Future<List<Evaluation>> fetchDashboards(DateTime start, DateTime end) async {
    // simulate
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return [
      Evaluation(
          id: '0',
          title: 'Rasio Likuiditas',
          yourValue: 4,
          idealText: '3 - 6 Bulan',),
      Evaluation(
          id: '1',
          title: 'Rasio aset lancar terhadap kekayaan bersih',
          yourValue: 8,
          idealText: '> 15%',),
      Evaluation(
          id: '2',
          title: 'Rasio utang terhadap aset',
          yourValue: 75,
          idealText: '≤ 50%',),
      Evaluation(
          id: '3', title: 'Rasio Tabungan', yourValue: 51, idealText: '≥ 10%',),
      Evaluation(
          id: '4',
          title: 'Rasio kemampuan pelunasan hutang',
          yourValue: 92,
          idealText: '> 45%',),
      Evaluation(
          id: '5',
          title: 'Aset investasi terhadap nilai bersih kekayaan',
          yourValue: 36,
          idealText: '≥ 50%',),
      Evaluation(id: '6', title: 'Rasio Solvabilitas', yourValue: 36),
    ];
  }

  Future<Evaluation> fetchDetail(String id) async {
    // same as above, filter by id
    final all = await fetchDashboards(DateTime.now(), DateTime.now());
    return all.firstWhere((e) => e.id == id);
  }

  Future<List<History>> fetchHistory() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return [
      History(
          start: DateTime(2024),
          end: DateTime(2024, 3, 31),
          ideal: 3,
          notIdeal: 2,
          incomplete: 1,),
      History(
          start: DateTime(2024, 4),
          end: DateTime(2024, 6, 30),
          ideal: 5,
          notIdeal: 0,
          incomplete: 1,),
      History(
          start: DateTime(2024, 7),
          end: DateTime(2024, 9, 30),
          ideal: 2,
          notIdeal: 4,
          incomplete: 0,),
    ];
  }
}
