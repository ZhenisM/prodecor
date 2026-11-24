import 'package:prodecor/core/store.dart';

/* ---------- примеры для показа, пока нет связи с 1С (как в кабинете: DEMO = true) ---------- */
const demo = true;

typedef Req = ({
  int? id,
  String number,
  String sentAt,
  String name,
  String client,
  List<String> dirs,
  String stage,
  String stageName,
  double sum,
  int count,
  bool demo,
});

final demoReq = <Req>[
  (
    id: null,
    number: '90502',
    sentAt: '2026-09-02',
    name: 'Дом в Таусамалы',
    client: 'Мадина Ержанова',
    dirs: ['paint'],
    stage: 'sold',
    stageName: '',
    sum: 2718500,
    count: 4,
    demo: true,
  ),
  (
    id: null,
    number: '90501',
    sentAt: '2026-10-09',
    name: 'Квартира в ЖК Esentai City',
    client: 'Айгерим Нурланова',
    dirs: ['light'],
    stage: 'inwork',
    stageName: '',
    sum: 382800,
    count: 6,
    demo: true,
  ),
];

/// Реальные отправленные заявки дизайнера
List<Req> realRequests(Store s) {
  final list = s.projects.where((p) => p.status == 'work').toList()
    ..sort((a, b) => b.sentAt.compareTo(a.sentAt) != 0 ? b.sentAt.compareTo(a.sentAt) : b.id - a.id);
  return list
      .map(
        (p) => (
          id: p.id,
          number: p.number,
          sentAt: p.sentAt,
          name: p.name,
          client: s.client(p.clientId)?.name ?? '',
          dirs: p.dirList,
          stage: p.stage,
          stageName: p.deal?.stageName ?? '',
          sum: (p.deal != null && p.deal!.sum > 0) ? p.deal!.sum : p.sum,
          count: p.count,
          demo: false,
        ),
      )
      .toList();
}
