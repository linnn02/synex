class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    this.iin,
    this.birthDate,
    this.address,
  });

  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final String? iin;
  final DateTime? birthDate;
  final String? address;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? 'Неизвестно',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: json['role'] as String? ?? 'PATIENT',
      iin: json['iin'] as String?,
      birthDate: json['birthDate'] == null
          ? null
          : DateTime.parse(json['birthDate'] as String),
      address: json['address'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class PatientProfile {
  const PatientProfile({
    required this.id,
    required this.userId,
    required this.fullName,
    this.iin,
    required this.relationType,
    required this.insuranceStatus,
    this.clinicId,
    this.primaryDoctorId,
    this.clinic,
    this.primaryDoctor,
  });

  final String id;
  final String userId;
  final String fullName;
  final String? iin;
  final String relationType;
  final String insuranceStatus;
  final String? clinicId;
  final String? primaryDoctorId;
  final Clinic? clinic;
  final DoctorProfile? primaryDoctor;

  factory PatientProfile.fromJson(Map<String, dynamic> json) {
    return PatientProfile(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      fullName: json['fullName'] as String? ?? 'Не указано',
      iin: json['iin'] as String?,
      relationType: json['relationType'] as String? ?? 'OTHER',
      insuranceStatus: json['insuranceStatus'] as String? ?? 'UNINSURED',
      clinicId: json['clinicId'] as String?,
      primaryDoctorId: json['primaryDoctorId'] as String?,
      clinic: json['clinic'] != null
          ? Clinic.fromJson(json['clinic'] as Map<String, dynamic>)
          : null,
      primaryDoctor: json['primaryDoctor'] != null
          ? DoctorProfile.fromJson(json['primaryDoctor'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatientProfile &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  String get relationLabel => switch (relationType) {
        'SELF' => 'Я',
        'CHILD' => 'Ребёнок',
        'MOTHER' => 'Мама',
        'FATHER' => 'Папа',
        'GRANDMOTHER' => 'Бабушка',
        'GRANDFATHER' => 'Дедушка',
        'OTHER' => 'Другое',
        _ => relationType,
      };
}

class Clinic {
  const Clinic({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    this.phone,
  });

  final String id;
  final String name;
  final String city;
  final String address;
  final String? phone;

  factory Clinic.fromJson(Map<String, dynamic> json) {
    return Clinic(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Не указана',
      city: json['city'] as String? ?? '',
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Clinic && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class DoctorProfile {
  const DoctorProfile({
    required this.id,
    required this.specialization,
    required this.user,
    required this.clinic,
    this.roomNumber,
    this.scheduleText,
  });

  final String id;
  final String specialization;
  final AppUser user;
  final Clinic clinic;
  final String? roomNumber;
  final String? scheduleText;

  factory DoctorProfile.fromJson(Map<String, dynamic> json) {
    return DoctorProfile(
      id: json['id'] as String? ?? '',
      specialization: json['specialization'] as String? ?? 'Врач',
      user: AppUser.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
      clinic: Clinic.fromJson(json['clinic'] as Map<String, dynamic>? ?? {}),
      roomNumber: json['roomNumber'] as String?,
      scheduleText: json['scheduleText'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DoctorProfile &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class Appointment {
  const Appointment({
    required this.id,
    required this.appointmentDate,
    required this.complaint,
    required this.status,
    required this.doctor,
    required this.clinic,
    this.patientProfile,
    this.prescriptionId,
    this.specialization,
    this.roomNumber,
  });

  final String id;
  final DateTime appointmentDate;
  final String complaint;
  final String status;
  final AppUser doctor;
  final Clinic clinic;
  final PatientProfile? patientProfile;
  final String? prescriptionId;
  final String? specialization;
  final String? roomNumber;

  factory Appointment.fromJson(Map<String, dynamic> json) {
    final doctorJson = json['doctor'] as Map<String, dynamic>;
    final doctorProfile = doctorJson['doctorProfile'] as Map<String, dynamic>?;
    return Appointment(
      id: json['id'] as String,
      appointmentDate: DateTime.parse(json['appointmentDate'] as String),
      complaint: json['complaint'] as String,
      status: json['status'] as String,
      doctor: AppUser.fromJson(doctorJson),
      clinic: Clinic.fromJson(json['clinic'] as Map<String, dynamic>? ?? {}),
      patientProfile: json['patientProfile'] != null
          ? PatientProfile.fromJson(
              json['patientProfile'] as Map<String, dynamic>)
          : null,
      prescriptionId:
          (json['prescription'] as Map<String, dynamic>?)?['id'] as String?,
      specialization: doctorProfile?['specialization'] as String?,
      roomNumber: doctorProfile?['roomNumber'] as String?,
    );
  }
}

class Prescription {
  const Prescription({
    required this.id,
    required this.diagnosis,
    required this.rawText,
    required this.status,
    required this.medicines,
    this.patientProfile,
    this.doctorComment,
    this.aiSummary,
    this.aiDisclaimer,
  });

  final String id;
  final String diagnosis;
  final String rawText;
  final String status;
  final String? doctorComment;
  final String? aiSummary;
  final String? aiDisclaimer;
  final List<PrescriptionMedicine> medicines;
  final PatientProfile? patientProfile;

  factory Prescription.fromJson(Map<String, dynamic> json) {
    final medicines = (json['medicines'] as List<dynamic>? ?? [])
        .map(
          (item) => PrescriptionMedicine.fromJson(item as Map<String, dynamic>),
        )
        .toList();

    return Prescription(
      id: json['id'] as String,
      diagnosis: json['diagnosis'] as String,
      rawText: json['rawText'] as String,
      status: json['status'] as String,
      doctorComment: json['doctorComment'] as String?,
      aiSummary: json['aiSummary'] as String?,
      aiDisclaimer: json['aiDisclaimer'] as String?,
      medicines: medicines,
      patientProfile: json['patientProfile'] != null
          ? PatientProfile.fromJson(
              json['patientProfile'] as Map<String, dynamic>)
          : null,
    );
  }
}

class PrescriptionMedicine {
  const PrescriptionMedicine({
    required this.id,
    required this.medicineName,
    required this.dosage,
    required this.frequency,
    required this.duration,
    required this.instruction,
    required this.quantityNeeded,
    required this.activeSubstance,
  });

  final String id;
  final String medicineName;
  final String dosage;
  final String frequency;
  final String duration;
  final String instruction;
  final int quantityNeeded;
  final String activeSubstance;

  factory PrescriptionMedicine.fromJson(Map<String, dynamic> json) {
    return PrescriptionMedicine(
      id: json['id'] as String,
      medicineName: json['medicineName'] as String,
      dosage: json['dosage'] as String,
      frequency: json['frequency'] as String,
      duration: json['duration'] as String,
      instruction: json['instruction'] as String,
      quantityNeeded: json['quantityNeeded'] as int,
      activeSubstance: json['activeSubstance'] as String,
    );
  }
}

class MarketProduct {
  const MarketProduct({
    required this.id,
    required this.title,
    required this.activeSubstance,
    required this.dosage,
    required this.form,
    required this.manufacturer,
    required this.price,
    required this.stock,
    required this.pharmacyName,
    required this.productUrl,
  });

  final String id;
  final String title;
  final String activeSubstance;
  final String dosage;
  final String form;
  final String manufacturer;
  final num price;
  final int stock;
  final String pharmacyName;
  final String productUrl;

  factory MarketProduct.fromJson(Map<String, dynamic> json) {
    return MarketProduct(
      id: json['id'] as String,
      title: json['title'] as String,
      activeSubstance: json['activeSubstance'] as String,
      dosage: json['dosage'] as String,
      form: json['form'] as String,
      manufacturer: json['manufacturer'] as String,
      price: json['price'] as num,
      stock: json['stock'] as int,
      pharmacyName: json['pharmacyName'] as String,
      productUrl: json['productUrl'] as String,
    );
  }
}

extension MarketProductView on MarketProduct {
  String get category {
    final normalized =
        '${title.toLowerCase()} $activeSubstance ${form.toLowerCase()}';

    if (normalized.contains('amoxicillin') ||
        normalized.contains('azithromycin') ||
        normalized.contains('амоксициллин') ||
        normalized.contains('азитромицин')) {
      return 'Антибиотики';
    }

    if (normalized.contains('ibuprofen') ||
        normalized.contains('paracetamol') ||
        normalized.contains('ибупрофен') ||
        normalized.contains('парацетамол')) {
      return 'Температура и боль';
    }

    if (normalized.contains('loratadine') ||
        normalized.contains('cetirizine') ||
        normalized.contains('лоратадин') ||
        normalized.contains('цетиризин')) {
      return 'Аллергия';
    }

    if (normalized.contains('спрей') || normalized.contains('горла')) {
      return 'Горло';
    }

    if (normalized.contains('vitamin') || normalized.contains('витамин')) {
      return 'Витамины';
    }

    return 'Другое';
  }

  bool get isInStock => stock > 0;

  String get priceText => '${price.toStringAsFixed(0)} ₸';
}

class CartItem {
  const CartItem({
    required this.id,
    required this.quantity,
    required this.product,
  });

  final String id;
  final int quantity;
  final MarketProduct product;

  num get lineTotal => product.price * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as String,
      quantity: json['quantity'] as int,
      product: MarketProduct.fromJson(json['product'] as Map<String, dynamic>),
    );
  }
}

class MedicineProductGroup {
  const MedicineProductGroup({
    required this.prescriptionMedicine,
    required this.products,
  });

  final PrescriptionMedicine prescriptionMedicine;
  final List<MarketProduct> products;

  factory MedicineProductGroup.fromJson(Map<String, dynamic> json) {
    final products = (json['products'] as List<dynamic>? ?? [])
        .map(
          (item) => MarketProduct.fromJson(
            item['product'] as Map<String, dynamic>,
          ),
        )
        .toList();

    return MedicineProductGroup(
      prescriptionMedicine: PrescriptionMedicine.fromJson(
        json['prescriptionMedicine'] as Map<String, dynamic>,
      ),
      products: products,
    );
  }
}

class MedicationScheduleItem {
  const MedicationScheduleItem({
    required this.id,
    required this.takeTime,
    required this.status,
    required this.prescriptionMedicine,
  });

  final String id;
  final DateTime takeTime;
  final String status;
  final PrescriptionMedicine prescriptionMedicine;

  factory MedicationScheduleItem.fromJson(Map<String, dynamic> json) {
    return MedicationScheduleItem(
      id: json['id'] as String,
      takeTime: DateTime.parse(json['takeTime'] as String),
      status: json['status'] as String,
      prescriptionMedicine: PrescriptionMedicine.fromJson(
        json['prescriptionMedicine'] as Map<String, dynamic>,
      ),
    );
  }
}
