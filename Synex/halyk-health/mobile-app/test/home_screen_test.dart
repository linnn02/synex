import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:halyk_health_patient/models/api_models.dart';
import 'package:halyk_health_patient/screens/home_screen.dart';
import 'package:halyk_health_patient/services/api_service.dart';

class _FakeHomeApiService extends ApiService {
  _FakeHomeApiService() : super(baseUrl: 'http://127.0.0.1:9/api');

  @override
  Future<List<Prescription>> getMyPrescriptions(
      {String? patientProfileId}) async {
    return const [
      Prescription(
        id: 'rx-1',
        diagnosis: 'Острый тонзиллит',
        rawText:
            'Амоксициллин 500 мг 3 раза в день 7 дней после еды. Ибупрофен 200 мг при температуре.',
        status: 'ACTIVE',
        aiSummary: 'Назначение включает антибиотик и жаропонижающее.',
        medicines: [
          PrescriptionMedicine(
            id: 'med-1',
            medicineName: 'Амоксициллин',
            dosage: '500 мг',
            frequency: '3 раза в день',
            duration: '7 дней',
            instruction: 'После еды',
            quantityNeeded: 21,
            activeSubstance: 'amoxicillin',
          ),
        ],
      ),
    ];
  }
}

void main() {
  testWidgets('renders Halyk-style home shell', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          apiService: _FakeHomeApiService(),
          enablePrescriptionPolling: false,
          user: const AppUser(
            id: 'patient-1',
            fullName: 'Айдана Смагулова',
            email: 'patient@test.kz',
            phone: '+77010000001',
            role: 'PATIENT',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Keeps this regression test readable when a layout change blanks the home.
    final renderedText =
        tester.allWidgets.whereType<Text>().map((text) => text.data).toList();
    expect(renderedText, contains('Поиск'));
    expect(find.textContaining('Поиск', skipOffstage: false), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Вам выписали назначение', skipOffstage: false),
        findsOneWidget);
    expect(find.text('Appteka', skipOffstage: false), findsWidgets);
  });
}
