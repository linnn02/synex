import {
  AppointmentStatus,
  InsuranceStatus,
  MatchType,
  PrismaClient,
  PrescriptionStatus,
  RelationType,
  ScheduleStatus,
  UserRole
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

  const therapistProfile = await prisma.doctorProfile.create({
    data: {
      userId: doctorTherapist.id,
      clinicId: clinic5.id,
      specialization: "Терапевт",
      roomNumber: "214",
      scheduleText: "Пн-Пт 09:00-17:00"
    }
  });

  const pediatricianProfile = await prisma.doctorProfile.create({
    data: {
      userId: doctorPediatrician.id,
      clinicId: clinicChild2.id,
      specialization: "Педиатр",
      roomNumber: "105",
      scheduleText: "Пн-Пт 08:00-16:00"
    }
  });

  const cardioProfile = await prisma.doctorProfile.create({
    data: {
      userId: doctorCardio.id,
      clinicId: clinic7.id,
      specialization: "Кардиолог",
      roomNumber: "302",
      scheduleText: "Пн-Пт 10:00-18:00"
    }
  });

  const selfProfile = await prisma.patientProfile.create({
    data: {
      userId: patient.id,
      fullName: "Айдана Смагулова",
      iin: "060512345678",
      relationType: RelationType.SELF,
      insuranceStatus: InsuranceStatus.ACTIVE,
      clinicId: clinic5.id,
      primaryDoctorId: therapistProfile.id
    }
  });

  const childProfile = await prisma.patientProfile.create({
    data: {
      userId: patient.id,
      fullName: "Аружан Смагулова",
      iin: "180412345678",
      relationType: RelationType.CHILD,
      insuranceStatus: InsuranceStatus.ACTIVE,
      clinicId: clinicChild2.id,
      primaryDoctorId: pediatricianProfile.id
    }
  });

  const motherProfile = await prisma.patientProfile.create({
    data: {
      userId: patient.id,
      fullName: "Гульмира Смагулова",
      iin: "760812345678",
      relationType: RelationType.MOTHER,
      insuranceStatus: InsuranceStatus.ACTIVE,
      clinicId: clinic7.id,
      primaryDoctorId: cardioProfile.id
    }
  });

  const confirmedAppointment = await prisma.appointment.create({
    data: {
      patientProfileId: selfProfile.id,
      doctorId: doctorTherapist.id,
      clinicId: clinic5.id,
      appointmentDate: appointmentDate(1, 9),
      complaint: "Плановый осмотр",
      status: AppointmentStatus.CONFIRMED
    }
  });

  await prisma.appointment.create({
    data: {
      patientProfileId: childProfile.id,
      doctorId: doctorPediatrician.id,
      clinicId: clinicChild2.id,
      appointmentDate: appointmentDate(2, 11),
      complaint: "Кашель у ребенка",
      status: AppointmentStatus.PENDING
    }
  });

  const completedMotherAppointment = await prisma.appointment.create({
    data: {
      patientProfileId: motherProfile.id,
      doctorId: doctorCardio.id,
      clinicId: clinic7.id,
      appointmentDate: appointmentDate(-5, 10),
      complaint: "Повышенное давление",
      status: AppointmentStatus.COMPLETED
    }
  });

  const products = await Promise.all(
    [
      {
        title: "Амоксициллин 500 мг",
        activeSubstance: "amoxicillin",
        dosage: "500 мг",
        form: "Капсулы",
        manufacturer: "Santo",
        price: 2150,
        stock: 42,
        pharmacyName: "Halyk Pharmacy",
        productUrl: "https://halyk-market.example/products/amoxicillin-500"
      },
      {
        title: "Амоксициллин DS 500 мг",
        activeSubstance: "amoxicillin",
        dosage: "500 мг",
        form: "Таблетки",
        manufacturer: "Nobel",
        price: 2380,
        stock: 18,
        pharmacyName: "Europharma",
        productUrl: "https://halyk-market.example/products/amoxicillin-ds-500"
      },
      {
        title: "Ибупрофен 200 мг",
        activeSubstance: "ibuprofen",
        dosage: "200 мг",
        form: "Таблетки",
        manufacturer: "Bayer",
        price: 980,
        stock: 65,
        pharmacyName: "Halyk Pharmacy",
        productUrl: "https://halyk-market.example/products/ibuprofen-200"
      },
      {
        title: "Нурофен 200 мг",
        activeSubstance: "ibuprofen",
        dosage: "200 мг",
        form: "Таблетки",
        manufacturer: "Reckitt",
        price: 1650,
        stock: 23,
        pharmacyName: "Аптека 36.6",
        productUrl: "https://halyk-market.example/products/nurofen-200"
      },
      {
        title: "Парацетамол 500 мг",
        activeSubstance: "paracetamol",
        dosage: "500 мг",
        form: "Таблетки",
        manufacturer: "Химфарм",
        price: 540,
        stock: 80,
        pharmacyName: "Halyk Pharmacy",
        productUrl: "https://halyk-market.example/products/paracetamol-500"
      },
      {
        title: "Парацетамол детский",
        activeSubstance: "paracetamol",
        dosage: "120 мг/5 мл",
        form: "Сироп",
        manufacturer: "Nobel",
        price: 850,
        stock: 30,
        pharmacyName: "Halyk Pharmacy",
        productUrl: "https://halyk-market.example/products/paracetamol-child"
      },
      {
        title: "Лоратадин 10 мг",
        activeSubstance: "loratadine",
        dosage: "10 мг",
        form: "Таблетки",
        manufacturer: "Sandoz",
        price: 1320,
        stock: 34,
        pharmacyName: "Europharma",
        productUrl: "https://halyk-market.example/products/loratadine-10"
      },
      {
        title: "Цетиризин 10 мг",
        activeSubstance: "cetirizine",
        dosage: "10 мг",
        form: "Таблетки",
        manufacturer: "Teva",
        price: 1490,
        stock: 25,
        pharmacyName: "Аптека 36.6",
        productUrl: "https://halyk-market.example/products/cetirizine-10"
      },
      {
        title: "Азитромицин 500 мг",
        activeSubstance: "azithromycin",
        dosage: "500 мг",
        form: "Таблетки",
        manufacturer: "Santo",
        price: 2890,
        stock: 12,
        pharmacyName: "Halyk Pharmacy",
        productUrl: "https://halyk-market.example/products/azithromycin-500"
      },
      {
        title: "Спрей для горла",
        activeSubstance: "benzydamine",
        dosage: "0.15%",
        form: "Спрей",
        manufacturer: "World Medicine",
        price: 1950,
        stock: 48,
        pharmacyName: "Europharma",
        productUrl: "https://halyk-market.example/products/throat-spray"
      },
      {
        title: "Витамин C 500 мг",
        activeSubstance: "ascorbic-acid",
        dosage: "500 мг",
        form: "Таблетки шипучие",
        manufacturer: "Doppelherz",
        price: 1750,
        stock: 58,
        pharmacyName: "Halyk Pharmacy",
        productUrl: "https://halyk-market.example/products/vitamin-c-500"
      },
      {
        title: "Эналаприл 10 мг",
        activeSubstance: "enalapril",
        dosage: "10 мг",
        form: "Таблетки",
        manufacturer: "Santo",
        price: 1200,
        stock: 50,
        pharmacyName: "Halyk Pharmacy",
        productUrl: "https://halyk-market.example/products/enalapril-10"
      }
    ].map((product) => prisma.marketProduct.create({ data: product }))
  );

  const findProduct = (activeSubstance: string) =>
    products.filter((product) => product.activeSubstance === activeSubstance);

  const respiratoryPrescription = await prisma.prescription.create({
    data: {
      appointmentId: confirmedAppointment.id,
      patientProfileId: selfProfile.id,
      doctorId: doctorTherapist.id,
      diagnosis: "Острый тонзиллит",
      rawText: "Амоксициллин 500 мг 3 раза в день 7 дней после еды. Ибупрофен 200 мг при температуре.",
      doctorComment: "Контроль состояния через 3 дня. При ухудшении самочувствия обратиться повторно.",
      aiSummary: "Назначение включает антибиотик курсом на 7 дней и жаропонижающее средство при необходимости.",
      aiDisclaimer,
      status: PrescriptionStatus.ACTIVE
    }
  });

  const amoxicillin = await prisma.prescriptionMedicine.create({
    data: {
      prescriptionId: respiratoryPrescription.id,
      medicineName: "Амоксициллин",
      dosage: "500 мг",
      frequency: "3 раза в день",
      duration: "7 дней",
      instruction: "После еды",
      quantityNeeded: 21,
      activeSubstance: "amoxicillin"
    }
  });

  const ibuprofen = await prisma.prescriptionMedicine.create({
    data: {
      prescriptionId: respiratoryPrescription.id,
      medicineName: "Ибупрофен",
      dosage: "200 мг",
      frequency: "При температуре",
      duration: "По необходимости",
      instruction: "Не превышать дозировку, указанную врачом",
      quantityNeeded: 1,
      activeSubstance: "ibuprofen"
    }
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
      ...scheduleTimes(7, [8, 14, 20]).map((takeTime) => ({
        patientProfileId: selfProfile.id,
        prescriptionMedicineId: amoxicillin.id,
        takeTime,
        status: ScheduleStatus.PLANNED
      })),
      ...scheduleTimes(1, [10]).map((takeTime) => ({
        patientProfileId: selfProfile.id,
        prescriptionMedicineId: ibuprofen.id,
        takeTime,
        status: ScheduleStatus.PLANNED
      }))
    ]
  });

  const pressurePrescription = await prisma.prescription.create({
    data: {
      appointmentId: completedMotherAppointment.id,
      patientProfileId: motherProfile.id,
      doctorId: doctorCardio.id,
      diagnosis: "Артериальная гипертензия",
      rawText: "Эналаприл 10 мг 1 раз в день 30 дней утром. Контроль давления ежедневно.",
      doctorComment: "Следить за пульсом и давлением.",
      aiSummary: "Назначен препарат для контроля давления на 30 дней с ежедневным приемом утром.",
      aiDisclaimer,
      status: PrescriptionStatus.ACTIVE
    }
  });

  const enalapril = await prisma.prescriptionMedicine.create({
    data: {
      prescriptionId: pressurePrescription.id,
      medicineName: "Эналаприл",
      dosage: "10 мг",
      frequency: "1 раз в день",
      duration: "30 дней",
      instruction: "Утром, в одно и то же время",
      quantityNeeded: 30,
      activeSubstance: "enalapril"
    }
  });

  const enalaprilProduct = findProduct("enalapril")[0];
  if (enalaprilProduct) {
    await prisma.medicineMatch.create({
      data: {
        prescriptionMedicineId: enalapril.id,
        productId: enalaprilProduct.id,
        matchType: MatchType.EXACT,
        confidenceScore: 0.96,
        isAlternative: false
      }
    });
  }

  await prisma.medicationSchedule.createMany({
    data: scheduleTimes(30, [9]).map((takeTime) => ({
      patientProfileId: motherProfile.id,
      prescriptionMedicineId: enalapril.id,
      takeTime,
      status: ScheduleStatus.PLANNED
    }))
  });

  console.log("Seed complete:");
  console.log("  Patient: patient@test.kz / 123456");
  console.log("  Doctor: doctor@test.kz / 123456");
  console.log("  Patient profiles: SELF, CHILD, MOTHER");
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
