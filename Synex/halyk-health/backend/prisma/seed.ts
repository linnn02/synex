import {
  AppointmentStatus,
  InsuranceStatus,
  MatchType,
  PrismaClient,
  PrescriptionStatus,
  RelationType,
  ScheduleStatus,
  UserRole,
  PharmacyStockMovementReason,
  PharmacyOrderStatus,
  PharmacyProductForm
} from "@prisma/client";
import bcrypt from "bcryptjs";


const prisma = new PrismaClient();

const aiDisclaimer =
  "ИИ-агент не заменяет врача. Он объясняет назначение, созданное врачом. Перед заменой препарата проконсультируйтесь с врачом или фармацевтом.";

function appointmentDate(dayOffset: number, hour: number, minute = 0) {
  const date = new Date();
  date.setDate(date.getDate() + dayOffset);
  date.setHours(hour, minute, 0, 0);
  return date;
}

function scheduleTimes(days: number, hours: number[]) {
  const rows: Date[] = [];
  for (let day = 0; day < days; day += 1) {
    for (const hour of hours) {
      const takeTime = new Date();
      takeTime.setDate(takeTime.getDate() + day);
      takeTime.setHours(hour, 0, 0, 0);
      rows.push(takeTime);
    }
  }
  return rows;
}

async function main() {
  // ─── Clean up ──────────────────────────────────────────────────────────────
  await prisma.pharmacyOrderItem.deleteMany();
  await prisma.pharmacyOrder.deleteMany();
  await prisma.pharmacyStockMovement.deleteMany();
  await prisma.pharmacyProduct.deleteMany();
  await prisma.pharmacyStaff.deleteMany();
  await prisma.pharmacy.deleteMany();
  await prisma.cartItem.deleteMany();
  await prisma.medicationSchedule.deleteMany();
  await prisma.medicineMatch.deleteMany();
  await prisma.prescriptionMedicine.deleteMany();
  await prisma.prescription.deleteMany();
  await prisma.appointment.deleteMany();
  await prisma.patientProfile.deleteMany();
  await prisma.doctorProfile.deleteMany();
  await prisma.marketProduct.deleteMany();
  await prisma.clinic.deleteMany();
  await prisma.user.deleteMany();

  const passwordHash = await bcrypt.hash("123456", 10);

  // ─── Medical users ─────────────────────────────────────────────────────────
  const patient = await prisma.user.create({
    data: {
      fullName: "Айдана Смагулова",
      iin: "060512345678",
      phone: "+77010000001",
      email: "patient@test.kz",
      passwordHash,
      role: UserRole.PATIENT,
      birthDate: new Date("1994-05-12"),
      address: "Алматы, мкр. Алмагуль, д. 12"
    }
  });

  const doctorTherapist = await prisma.user.create({
    data: {
      fullName: "Доктор Алия Нурланова",
      phone: "+77010000002",
      email: "doctor@test.kz",
      passwordHash,
      role: UserRole.DOCTOR
    }
  });

  const doctorPediatrician = await prisma.user.create({
    data: {
      fullName: "Омарова Лаура Сериковна",
      phone: "+77010000003",
      email: "doctor2@test.kz",
      passwordHash,
      role: UserRole.DOCTOR
    }
  });

  const doctorCardio = await prisma.user.create({
    data: {
      fullName: "Ахметова Динара Болатовна",
      phone: "+77010000004",
      email: "doctor3@test.kz",
      passwordHash,
      role: UserRole.DOCTOR
    }
  });

  // ─── Pharmacy users ────────────────────────────────────────────────────────
  const pharmacyAdmin1 = await prisma.user.create({
    data: {
      fullName: "Айгерим Бектурова",
      phone: "+77010000010",
      email: "pharmacy@test.kz",
      passwordHash,
      role: UserRole.PHARMACY_ADMIN
    }
  });

  const pharmacyStaff1 = await prisma.user.create({
    data: {
      fullName: "Нурлан Сейтов",
      phone: "+77010000011",
      email: "pharmacy.staff@test.kz",
      passwordHash,
      role: UserRole.PHARMACY_STAFF
    }
  });

  const pharmacyAdmin2 = await prisma.user.create({
    data: {
      fullName: "Гульнара Ахметова",
      phone: "+77010000012",
      email: "pharmacy2@test.kz",
      passwordHash,
      role: UserRole.PHARMACY_ADMIN
    }
  });

  // ─── Clinics ───────────────────────────────────────────────────────────────
  const clinic5 = await prisma.clinic.create({
    data: {
      name: "Городская поликлиника №5",
      city: "Алматы",
      address: "ул. Абая 120, Алматы",
      bin: "990140000005",
      phone: "+77273000005"
    }
  });

  const clinicChild2 = await prisma.clinic.create({
    data: {
      name: "Детская поликлиника №2",
      city: "Алматы",
      address: "ул. Макатаева 10, Алматы",
      bin: "990140000002",
      phone: "+77273000002"
    }
  });

  const clinic7 = await prisma.clinic.create({
    data: {
      name: "Городская поликлиника №7",
      city: "Алматы",
      address: "ул. Розыбакиева 200, Алматы",
      bin: "990140000007",
      phone: "+77273000007"
    }
  });

  // ─── Doctor profiles ───────────────────────────────────────────────────────
  const therapistProfile = await prisma.doctorProfile.create({
    data: { userId: doctorTherapist.id, clinicId: clinic5.id, specialization: "Терапевт", roomNumber: "214", scheduleText: "Пн-Пт 09:00-17:00" }
  });

  const pediatricianProfile = await prisma.doctorProfile.create({
    data: { userId: doctorPediatrician.id, clinicId: clinicChild2.id, specialization: "Педиатр", roomNumber: "105", scheduleText: "Пн-Пт 08:00-16:00" }
  });

  const cardioProfile = await prisma.doctorProfile.create({
    data: { userId: doctorCardio.id, clinicId: clinic7.id, specialization: "Кардиолог", roomNumber: "302", scheduleText: "Пн-Пт 10:00-18:00" }
  });

  // ─── Patient profiles ──────────────────────────────────────────────────────
  const selfProfile = await prisma.patientProfile.create({
    data: { userId: patient.id, fullName: "Айдана Смагулова", iin: "060512345678", relationType: RelationType.SELF, insuranceStatus: InsuranceStatus.ACTIVE, clinicId: clinic5.id, primaryDoctorId: therapistProfile.id }
  });

  const childProfile = await prisma.patientProfile.create({
    data: { userId: patient.id, fullName: "Аружан Смагулова", iin: "180412345678", relationType: RelationType.CHILD, insuranceStatus: InsuranceStatus.ACTIVE, clinicId: clinicChild2.id, primaryDoctorId: pediatricianProfile.id }
  });

  const motherProfile = await prisma.patientProfile.create({
    data: { userId: patient.id, fullName: "Гульмира Смагулова", iin: "760812345678", relationType: RelationType.MOTHER, insuranceStatus: InsuranceStatus.ACTIVE, clinicId: clinic7.id, primaryDoctorId: cardioProfile.id }
  });

  // ─── Appointments ──────────────────────────────────────────────────────────
  const confirmedAppointment = await prisma.appointment.create({
    data: { patientProfileId: selfProfile.id, doctorId: doctorTherapist.id, clinicId: clinic5.id, appointmentDate: appointmentDate(1, 9), complaint: "Плановый осмотр", status: AppointmentStatus.CONFIRMED }
  });

  await prisma.appointment.create({
    data: { patientProfileId: childProfile.id, doctorId: doctorPediatrician.id, clinicId: clinicChild2.id, appointmentDate: appointmentDate(2, 11), complaint: "Кашель у ребенка", status: AppointmentStatus.PENDING }
  });

  const completedMotherAppointment = await prisma.appointment.create({
    data: { patientProfileId: motherProfile.id, doctorId: doctorCardio.id, clinicId: clinic7.id, appointmentDate: appointmentDate(-5, 10), complaint: "Повышенное давление", status: AppointmentStatus.COMPLETED }
  });

  // ─── Market products (global catalog) ─────────────────────────────────────
  const products = await Promise.all(
    [
      { title: "Амоксициллин 500 мг", activeSubstance: "amoxicillin", dosage: "500 мг", form: "Капсулы", manufacturer: "Santo", price: 2150, stock: 42, pharmacyName: "Halyk Pharmacy №1", productUrl: "https://halyk-market.example/products/amoxicillin-500" },
      { title: "Амоксициллин DS 500 мг", activeSubstance: "amoxicillin", dosage: "500 мг", form: "Таблетки", manufacturer: "Nobel", price: 2380, stock: 18, pharmacyName: "Europharma", productUrl: "https://halyk-market.example/products/amoxicillin-ds-500" },
      { title: "Ибупрофен 200 мг", activeSubstance: "ibuprofen", dosage: "200 мг", form: "Таблетки", manufacturer: "Bayer", price: 980, stock: 65, pharmacyName: "Halyk Pharmacy №1", productUrl: "https://halyk-market.example/products/ibuprofen-200" },
      { title: "Нурофен 200 мг", activeSubstance: "ibuprofen", dosage: "200 мг", form: "Таблетки", manufacturer: "Reckitt", price: 1650, stock: 23, pharmacyName: "Европа Аптека", productUrl: "https://halyk-market.example/products/nurofen-200" },
      { title: "Парацетамол 500 мг", activeSubstance: "paracetamol", dosage: "500 мг", form: "Таблетки", manufacturer: "Химфарм", price: 540, stock: 80, pharmacyName: "Halyk Pharmacy №1", productUrl: "https://halyk-market.example/products/paracetamol-500" },
      { title: "Парацетамол детский", activeSubstance: "paracetamol", dosage: "120 мг/5 мл", form: "Сироп", manufacturer: "Nobel", price: 850, stock: 30, pharmacyName: "Halyk Pharmacy №1", productUrl: "https://halyk-market.example/products/paracetamol-child" },
      { title: "Лоратадин 10 мг", activeSubstance: "loratadine", dosage: "10 мг", form: "Таблетки", manufacturer: "Sandoz", price: 1320, stock: 34, pharmacyName: "Europharma", productUrl: "https://halyk-market.example/products/loratadine-10" },
      { title: "Цетиризин 10 мг", activeSubstance: "cetirizine", dosage: "10 мг", form: "Таблетки", manufacturer: "Teva", price: 1490, stock: 25, pharmacyName: "Европа Аптека", productUrl: "https://halyk-market.example/products/cetirizine-10" },
      { title: "Азитромицин 500 мг", activeSubstance: "azithromycin", dosage: "500 мг", form: "Таблетки", manufacturer: "Santo", price: 2890, stock: 12, pharmacyName: "Halyk Pharmacy №1", productUrl: "https://halyk-market.example/products/azithromycin-500" },
      { title: "Спрей для горла", activeSubstance: "benzydamine", dosage: "0.15%", form: "Спрей", manufacturer: "World Medicine", price: 1950, stock: 48, pharmacyName: "Europharma", productUrl: "https://halyk-market.example/products/throat-spray" },
      { title: "Витамин C 500 мг", activeSubstance: "ascorbic-acid", dosage: "500 мг", form: "Таблетки шипучие", manufacturer: "Doppelherz", price: 1750, stock: 58, pharmacyName: "Halyk Pharmacy №1", productUrl: "https://halyk-market.example/products/vitamin-c-500" },
      { title: "Эналаприл 10 мг", activeSubstance: "enalapril", dosage: "10 мг", form: "Таблетки", manufacturer: "Santo", price: 1200, stock: 50, pharmacyName: "Halyk Pharmacy №1", productUrl: "https://halyk-market.example/products/enalapril-10" }
    ].map((product) => prisma.marketProduct.create({ data: product }))
  );

  const findProduct = (activeSubstance: string) =>
    products.filter((product) => product.activeSubstance === activeSubstance);

  // ─── Prescriptions ─────────────────────────────────────────────────────────
  const respiratoryPrescription = await prisma.prescription.create({
    data: { appointmentId: confirmedAppointment.id, patientProfileId: selfProfile.id, doctorId: doctorTherapist.id, diagnosis: "Острый тонзиллит", rawText: "Амоксициллин 500 мг 3 раза в день 7 дней после еды. Ибупрофен 200 мг при температуре.", doctorComment: "Контроль состояния через 3 дня.", aiSummary: "Назначение включает антибиотик курсом на 7 дней и жаропонижающее.", aiDisclaimer, status: PrescriptionStatus.ACTIVE }
  });

  const amoxicillin = await prisma.prescriptionMedicine.create({
    data: { prescriptionId: respiratoryPrescription.id, medicineName: "Амоксициллин", dosage: "500 мг", frequency: "3 раза в день", duration: "7 дней", instruction: "После еды", quantityNeeded: 21, activeSubstance: "amoxicillin" }
  });

  const ibuprofen = await prisma.prescriptionMedicine.create({
    data: { prescriptionId: respiratoryPrescription.id, medicineName: "Ибупрофен", dosage: "200 мг", frequency: "При температуре", duration: "По необходимости", instruction: "Не превышать дозировку", quantityNeeded: 1, activeSubstance: "ibuprofen" }
  });

  for (const medicine of [amoxicillin, ibuprofen]) {
    const matchedProducts = findProduct(medicine.activeSubstance);
    await prisma.medicineMatch.createMany({
      data: matchedProducts.map((product, index) => ({
        prescriptionMedicineId: medicine.id,
        productId: product.id,
        matchType: index === 0 ? MatchType.EXACT : MatchType.ACTIVE_SUBSTANCE,
        confidenceScore: index === 0 ? 0.96 : 0.86,
        isAlternative: index !== 0
      }))
    });
  }

  await prisma.medicationSchedule.createMany({
    data: [
      ...scheduleTimes(7, [8, 14, 20]).map((takeTime) => ({ patientProfileId: selfProfile.id, prescriptionMedicineId: amoxicillin.id, takeTime, status: ScheduleStatus.PLANNED })),
      ...scheduleTimes(1, [10]).map((takeTime) => ({ patientProfileId: selfProfile.id, prescriptionMedicineId: ibuprofen.id, takeTime, status: ScheduleStatus.PLANNED }))
    ]
  });

  const pressurePrescription = await prisma.prescription.create({
    data: { appointmentId: completedMotherAppointment.id, patientProfileId: motherProfile.id, doctorId: doctorCardio.id, diagnosis: "Артериальная гипертензия", rawText: "Эналаприл 10 мг 1 раз в день 30 дней утром.", doctorComment: "Следить за пульсом и давлением.", aiSummary: "Назначен препарат для контроля давления на 30 дней.", aiDisclaimer, status: PrescriptionStatus.ACTIVE }
  });

  const enalapril = await prisma.prescriptionMedicine.create({
    data: { prescriptionId: pressurePrescription.id, medicineName: "Эналаприл", dosage: "10 мг", frequency: "1 раз в день", duration: "30 дней", instruction: "Утром, в одно и то же время", quantityNeeded: 30, activeSubstance: "enalapril" }
  });

  const enalaprilProduct = findProduct("enalapril")[0];
  if (enalaprilProduct) {
    await prisma.medicineMatch.create({ data: { prescriptionMedicineId: enalapril.id, productId: enalaprilProduct.id, matchType: MatchType.EXACT, confidenceScore: 0.96, isAlternative: false } });
  }

  await prisma.medicationSchedule.createMany({
    data: scheduleTimes(30, [9]).map((takeTime) => ({ patientProfileId: motherProfile.id, prescriptionMedicineId: enalapril.id, takeTime, status: ScheduleStatus.PLANNED }))
  });

  // ─── Pharmacy 1: Halyk Pharmacy №1 ────────────────────────────────────────
  const pharmacy1 = await prisma.pharmacy.create({
    data: {
      name: "Halyk Pharmacy №1",
      bin: "240540001234",
      address: "пр. Абая 52, Алматы",
      city: "Алматы",
      phone: "+7 727 000 00 01",
      email: "pharmacy1@halyk.kz",
      workingHours: "08:00–22:00 ежедневно",
      deliveryEnabled: true,
      pickupEnabled: true
    }
  });

  await prisma.pharmacyStaff.create({ data: { userId: pharmacyAdmin1.id, pharmacyId: pharmacy1.id, isActive: true } });
  await prisma.pharmacyStaff.create({ data: { userId: pharmacyStaff1.id, pharmacyId: pharmacy1.id, isActive: true } });

  // Pharmacy 1 products
  const p1Products = await Promise.all([
    prisma.pharmacyProduct.create({ data: { pharmacyId: pharmacy1.id, name: "Амоксициллин 500 мг", activeSubstance: "amoxicillin", dosage: "500 мг", form: PharmacyProductForm.CAPSULE, category: "Антибиотики", manufacturer: "Santo", price: 2150, stock: 42, minStock: 10, isAvailable: true, requiresPrescription: true, description: "Антибиотик широкого спектра действия" } }),
    prisma.pharmacyProduct.create({ data: { pharmacyId: pharmacy1.id, name: "Ибупрофен 200 мг", activeSubstance: "ibuprofen", dosage: "200 мг", form: PharmacyProductForm.TABLET, category: "НПВС", manufacturer: "Bayer", price: 980, stock: 65, minStock: 15, isAvailable: true, requiresPrescription: false } }),
    prisma.pharmacyProduct.create({ data: { pharmacyId: pharmacy1.id, name: "Нурофен 200 мг", activeSubstance: "ibuprofen", dosage: "200 мг", form: PharmacyProductForm.TABLET, category: "НПВС", manufacturer: "Reckitt", price: 1650, stock: 4, minStock: 10, isAvailable: true, requiresPrescription: false, description: "Нурофен с ибупрофеном в оболочке" } }),
    prisma.pharmacyProduct.create({ data: { pharmacyId: pharmacy1.id, name: "Парацетамол 500 мг", activeSubstance: "paracetamol", dosage: "500 мг", form: PharmacyProductForm.TABLET, category: "Жаропонижающие", manufacturer: "Химфарм", price: 540, stock: 80, minStock: 20, isAvailable: true, requiresPrescription: false } }),
    prisma.pharmacyProduct.create({ data: { pharmacyId: pharmacy1.id, name: "Амброксол сироп 15мг/5мл", activeSubstance: "ambroxol", dosage: "15 мг/5 мл", form: PharmacyProductForm.SYRUP, category: "Отхаркивающие", manufacturer: "Hexal", price: 1320, stock: 28, minStock: 8, isAvailable: true, requiresPrescription: false } }),
    prisma.pharmacyProduct.create({ data: { pharmacyId: pharmacy1.id, name: "Витамин C 500 мг", activeSubstance: "ascorbic-acid", dosage: "500 мг", form: PharmacyProductForm.TABLET, category: "Витамины", manufacturer: "Doppelherz", price: 1750, stock: 0, minStock: 10, isAvailable: false, requiresPrescription: false } }),
    prisma.pharmacyProduct.create({ data: { pharmacyId: pharmacy1.id, name: "Лоратадин 10 мг", activeSubstance: "loratadine", dosage: "10 мг", form: PharmacyProductForm.TABLET, category: "Антигистаминные", manufacturer: "Sandoz", price: 1320, stock: 34, minStock: 10, isAvailable: true, requiresPrescription: false } }),
    prisma.pharmacyProduct.create({ data: { pharmacyId: pharmacy1.id, name: "Цетиризин 10 мг", activeSubstance: "cetirizine", dosage: "10 мг", form: PharmacyProductForm.TABLET, category: "Антигистаминные", manufacturer: "Teva", price: 1490, stock: 3, minStock: 10, isAvailable: true, requiresPrescription: false } }),
    prisma.pharmacyProduct.create({ data: { pharmacyId: pharmacy1.id, name: "Эналаприл 10 мг", activeSubstance: "enalapril", dosage: "10 мг", form: PharmacyProductForm.TABLET, category: "Кардиология", manufacturer: "Santo", price: 1200, stock: 50, minStock: 15, isAvailable: true, requiresPrescription: true } }),
    prisma.pharmacyProduct.create({ data: { pharmacyId: pharmacy1.id, name: "Аква Марис назальный", activeSubstance: "sodium-chloride", dosage: "0.9%", form: PharmacyProductForm.SPRAY, category: "ЛОР", manufacturer: "Jadran", price: 1890, stock: 20, minStock: 5, isAvailable: true, requiresPrescription: false } }),
    prisma.pharmacyProduct.create({ data: { pharmacyId: pharmacy1.id, name: "Називин 0.05%", activeSubstance: "oxymetazoline", dosage: "0.05%", form: PharmacyProductForm.DROPS, category: "ЛОР", manufacturer: "Merck", price: 1340, stock: 15, minStock: 5, isAvailable: true, requiresPrescription: false } }),
    prisma.pharmacyProduct.create({ data: { pharmacyId: pharmacy1.id, name: "Лазолван сироп", activeSubstance: "ambroxol", dosage: "15 мг/5 мл", form: PharmacyProductForm.SYRUP, category: "Отхаркивающие", manufacturer: "Boehringer", price: 2100, stock: 2, minStock: 8, isAvailable: true, requiresPrescription: false } }),
  ]);

  // Stock movements for pharmacy 1
  await prisma.pharmacyStockMovement.createMany({
    data: [
      { productId: p1Products[0].id, quantity: 50, reason: PharmacyStockMovementReason.SUPPLY, comment: "Поставка от Sant", createdBy: pharmacyAdmin1.id },
      { productId: p1Products[0].id, quantity: -8, reason: PharmacyStockMovementReason.SALE, comment: "Продажа", createdBy: pharmacyStaff1.id },
      { productId: p1Products[2].id, quantity: 20, reason: PharmacyStockMovementReason.SUPPLY, comment: "Поставка Reckitt", createdBy: pharmacyAdmin1.id },
      { productId: p1Products[2].id, quantity: -16, reason: PharmacyStockMovementReason.SALE, comment: "Розничные продажи", createdBy: pharmacyStaff1.id },
      { productId: p1Products[5].id, quantity: 30, reason: PharmacyStockMovementReason.SUPPLY, comment: "Начальный остаток", createdBy: pharmacyAdmin1.id },
      { productId: p1Products[5].id, quantity: -30, reason: PharmacyStockMovementReason.SALE, comment: "Распродано", createdBy: pharmacyStaff1.id },
    ]
  });

  // Pharmacy orders
  const order1 = await prisma.pharmacyOrder.create({
    data: {
      pharmacyId: pharmacy1.id,
      patientName: "Айдана Смагулова",
      patientPhone: "+77010000001",
      totalPrice: 3130,
      deliveryType: "pickup",
      status: PharmacyOrderStatus.NEW,
      comment: "Жду звонка для подтверждения"
    }
  });

  await prisma.pharmacyOrderItem.createMany({
    data: [
      { orderId: order1.id, productId: p1Products[0].id, productName: "Амоксициллин 500 мг", quantity: 1, unitPrice: 2150, isAvailable: true },
      { orderId: order1.id, productId: p1Products[1].id, productName: "Ибупрофен 200 мг", quantity: 1, unitPrice: 980, isAvailable: true }
    ]
  });

  const order2 = await prisma.pharmacyOrder.create({
    data: {
      pharmacyId: pharmacy1.id,
      patientName: "Болат Сейтов",
      patientPhone: "+77012345678",
      totalPrice: 2640,
      deliveryType: "delivery",
      deliveryAddress: "ул. Алматинская, д. 5, кв. 12",
      status: PharmacyOrderStatus.CONFIRMED
    }
  });

  await prisma.pharmacyOrderItem.createMany({
    data: [
      { orderId: order2.id, productId: p1Products[6].id, productName: "Лоратадин 10 мг", quantity: 2, unitPrice: 1320, isAvailable: true }
    ]
  });

  const order3 = await prisma.pharmacyOrder.create({
    data: {
      pharmacyId: pharmacy1.id,
      patientName: "Гульмира Смагулова",
      patientPhone: "+77010000001",
      totalPrice: 5900,
      deliveryType: "delivery",
      deliveryAddress: "пр. Абая 52, кв. 3",
      status: PharmacyOrderStatus.PREPARING,
      comment: "Доставка после 18:00"
    }
  });

  await prisma.pharmacyOrderItem.createMany({
    data: [
      { orderId: order3.id, productId: p1Products[8].id, productName: "Эналаприл 10 мг", quantity: 3, unitPrice: 1200, isAvailable: true },
      { orderId: order3.id, productId: p1Products[9].id, productName: "Аква Марис", quantity: 1, unitPrice: 1890, isAvailable: true },
      { orderId: order3.id, productId: p1Products[5].id, productName: "Витамин C 500 мг", quantity: 1, unitPrice: 1750, isAvailable: false }
    ]
  });

  const order4 = await prisma.pharmacyOrder.create({
    data: {
      pharmacyId: pharmacy1.id,
      patientName: "Алибек Таженов",
      patientPhone: "+77775554433",
      totalPrice: 4590,
      deliveryType: "pickup",
      status: PharmacyOrderStatus.COMPLETED
    }
  });

  await prisma.pharmacyOrderItem.createMany({
    data: [
      { orderId: order4.id, productId: p1Products[3].id, productName: "Парацетамол 500 мг", quantity: 3, unitPrice: 540, isAvailable: true },
      { orderId: order4.id, productId: p1Products[4].id, productName: "Амброксол сироп", quantity: 2, unitPrice: 1320, isAvailable: true }
    ]
  });

  const order5 = await prisma.pharmacyOrder.create({
    data: {
      pharmacyId: pharmacy1.id,
      patientName: "Дамир Усенов",
      patientPhone: "+77070123456",
      totalPrice: 1490,
      deliveryType: "pickup",
      status: PharmacyOrderStatus.OUT_OF_STOCK,
      comment: "Нет в наличии"
    }
  });

  await prisma.pharmacyOrderItem.createMany({
    data: [{ orderId: order5.id, productId: p1Products[7].id, productName: "Цетиризин 10 мг", quantity: 1, unitPrice: 1490, isAvailable: false }]
  });

  // ─── Pharmacy 2 ────────────────────────────────────────────────────────────
  const pharmacy2 = await prisma.pharmacy.create({
    data: {
      name: "Europharma Алматы",
      bin: "240540009988",
      address: "ул. Сейфуллина 506, Алматы",
      city: "Алматы",
      phone: "+7 727 000 00 02",
      email: "europharma@test.kz",
      workingHours: "09:00–21:00 Пн-Сб",
      deliveryEnabled: false,
      pickupEnabled: true
    }
  });

  await prisma.pharmacyStaff.create({ data: { userId: pharmacyAdmin2.id, pharmacyId: pharmacy2.id, isActive: true } });

  await prisma.pharmacyProduct.createMany({
    data: [
      { pharmacyId: pharmacy2.id, name: "Азитромицин 500 мг", activeSubstance: "azithromycin", dosage: "500 мг", form: PharmacyProductForm.TABLET, category: "Антибиотики", manufacturer: "Santo", price: 2890, stock: 12, minStock: 5, isAvailable: true, requiresPrescription: true },
      { pharmacyId: pharmacy2.id, name: "Спрей для горла Тантум Верде", activeSubstance: "benzydamine", dosage: "0.15%", form: PharmacyProductForm.SPRAY, category: "ЛОР", manufacturer: "Recordati", price: 1950, stock: 8, minStock: 3, isAvailable: true, requiresPrescription: false },
      { pharmacyId: pharmacy2.id, name: "Лоратадин 10 мг", activeSubstance: "loratadine", dosage: "10 мг", form: PharmacyProductForm.TABLET, category: "Антигистаминные", manufacturer: "Teva", price: 1100, stock: 20, minStock: 5, isAvailable: true, requiresPrescription: false }
    ]
  });

  console.log("✅ Seed complete:");
  console.log("  Patient:          patient@test.kz / 123456");
  console.log("  Doctor:           doctor@test.kz / 123456");
  console.log("  Pharmacy Admin 1: pharmacy@test.kz / 123456  →  Halyk Pharmacy №1");
  console.log("  Pharmacy Staff:   pharmacy.staff@test.kz / 123456");
  console.log("  Pharmacy Admin 2: pharmacy2@test.kz / 123456  →  Europharma Алматы");
  console.log(`  Market products: ${products.length}`);
}

main()
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

