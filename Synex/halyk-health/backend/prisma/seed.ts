import { PrismaClient, UserRole, AppointmentStatus, PrescriptionStatus, RelationType, InsuranceStatus } from "@prisma/client";
import bcrypt from "bcryptjs";

const prisma = new PrismaClient();

async function main() {
  // Clear all data in correct dependency order
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

  // --- Users ---
  const user = await prisma.user.create({
    data: {
      fullName: "Айгерим Нурланова",
      iin: "060512345678",
      phone: "+77010000001",
      email: "patient@test.kz",
      passwordHash,
      role: UserRole.PATIENT,
      birthDate: new Date("1994-05-12"),
      address: "Алматы, мкр. Алмагуль, д. 12"
    }
  });

  const doctor1 = await prisma.user.create({
    data: {
      fullName: "Смагулова Айгуль Ерлановна",
      phone: "+77010000002",
      email: "doctor1@test.kz",
      passwordHash,
      role: UserRole.DOCTOR
    }
  });

  const doctor2 = await prisma.user.create({
    data: {
      fullName: "Омарова Лаура Сериковна",
      phone: "+77010000003",
      email: "doctor2@test.kz",
      passwordHash,
      role: UserRole.DOCTOR
    }
  });

  const doctor3 = await prisma.user.create({
    data: {
      fullName: "Ахметова Динара Болатовна",
      phone: "+77010000004",
      email: "doctor3@test.kz",
      passwordHash,
      role: UserRole.DOCTOR
    }
  });

  // --- Clinics ---
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

  // --- Doctor Profiles ---
  const dp1 = await prisma.doctorProfile.create({
    data: {
      userId: doctor1.id,
      clinicId: clinic5.id,
      specialization: "Терапевт",
      roomNumber: "214",
      scheduleText: "Пн-Пт 09:00-17:00"
    }
  });

  const dp2 = await prisma.doctorProfile.create({
    data: {
      userId: doctor2.id,
      clinicId: clinicChild2.id,
      specialization: "Педиатр",
      roomNumber: "105",
      scheduleText: "Пн-Пт 08:00-16:00"
    }
  });

  const dp3 = await prisma.doctorProfile.create({
    data: {
      userId: doctor3.id,
      clinicId: clinic7.id,
      specialization: "Терапевт",
      roomNumber: "302",
      scheduleText: "Пн-Пт 10:00-18:00"
    }
  });

  // --- Patient Profiles ---
  const selfProfile = await prisma.patientProfile.create({
    data: {
      userId: user.id,
      fullName: "Айгерим Нурланова",
      iin: "060512345678",
      relationType: RelationType.SELF,
      insuranceStatus: InsuranceStatus.ACTIVE,
      clinicId: clinic5.id,
      primaryDoctorId: dp1.id
    }
  });

  const childProfile = await prisma.patientProfile.create({
    data: {
      userId: user.id,
      fullName: "Аружан Нурланова",
      iin: "180412345678",
      relationType: RelationType.CHILD,
      insuranceStatus: InsuranceStatus.ACTIVE,
      clinicId: clinicChild2.id,
      primaryDoctorId: dp2.id
    }
  });

  const motherProfile = await prisma.patientProfile.create({
    data: {
      userId: user.id,
      fullName: "Гульмира Нурланова",
      iin: "760812345678",
      relationType: RelationType.MOTHER,
      insuranceStatus: InsuranceStatus.ACTIVE,
      clinicId: clinic7.id,
      primaryDoctorId: dp3.id
    }
  });

  // --- Appointments ---
  const now = new Date();
  const appointmentDate = (dayOffset: number, hour: number, minute = 0) => {
    const date = new Date(now);
    date.setDate(date.getDate() + dayOffset);
    date.setHours(hour, minute, 0, 0);
    return date;
  };

  // SELF appointment
  await prisma.appointment.create({
    data: {
      patientProfileId: selfProfile.id,
      doctorId: doctor1.id,
      clinicId: clinic5.id,
      appointmentDate: appointmentDate(1, 9),
      complaint: "Плановый осмотр",
      status: AppointmentStatus.CONFIRMED
    }
  });

  // CHILD appointment
  await prisma.appointment.create({
    data: {
      patientProfileId: childProfile.id,
      doctorId: doctor2.id,
      clinicId: clinicChild2.id,
      appointmentDate: appointmentDate(2, 11),
      complaint: "Кашель у ребенка",
      status: AppointmentStatus.PENDING
    }
  });

  // MOTHER appointment
  const completedApt = await prisma.appointment.create({
    data: {
      patientProfileId: motherProfile.id,
      doctorId: doctor3.id,
      clinicId: clinic7.id,
      appointmentDate: appointmentDate(-5, 10),
      complaint: "Давление",
      status: AppointmentStatus.COMPLETED
    }
  });

  // Prescription for Mother
  const prescription = await prisma.prescription.create({
    data: {
      appointmentId: completedApt.id,
      patientProfileId: motherProfile.id,
      doctorId: doctor3.id,
      diagnosis: "Артериальная гипертензия",
      rawText: "Принимать препараты от давления регулярно. Покой, диета.",
      doctorComment: "Следить за пульсом.",
      status: PrescriptionStatus.ACTIVE
    }
  });

  await prisma.prescriptionMedicine.create({
    data: {
      prescriptionId: prescription.id,
      medicineName: "Эналаприл 10 мг",
      dosage: "10 мг",
      frequency: "1 раз в день",
      duration: "30 дней",
      instruction: "Утром натощак",
      quantityNeeded: 30,
      activeSubstance: "enalapril"
    }
  });

  // --- Market Products ---
  await prisma.marketProduct.createMany({
    data: [
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
      }
    ]
  });

  console.log("✅ Seed complete:");
  console.log("   Main User: patient@test.kz / 123456");
  console.log("   Profiles: SELF (Айгерим), CHILD (Аружан), MOTHER (Гульмира)");
}

main()
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
