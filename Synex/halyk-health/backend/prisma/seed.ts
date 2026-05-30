import { PrismaClient, UserRole, AppointmentStatus, PrescriptionStatus } from "@prisma/client";
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
  await prisma.doctorProfile.deleteMany();
  await prisma.marketProduct.deleteMany();
  await prisma.clinic.deleteMany();
  await prisma.user.deleteMany();

  const passwordHash = await bcrypt.hash("123456", 10);

  // --- Users ---
  const patient = await prisma.user.create({
    data: {
      fullName: "Айдана Смагулова",
      iin: "920815350112",
      phone: "+77010000001",
      email: "patient@test.kz",
      passwordHash,
      role: UserRole.PATIENT,
      birthDate: new Date("1994-04-12"),
      address: "Алматы, мкр. Алмагуль, д. 12"
    }
  });

  const doctor = await prisma.user.create({
    data: {
      fullName: "Алия Нурланова",
      phone: "+77010000002",
      email: "doctor@test.kz",
      passwordHash,
      role: UserRole.DOCTOR
    }
  });

  const doctor2 = await prisma.user.create({
    data: {
      fullName: "Дмитрий Иванов",
      phone: "+77010000003",
      email: "doctor2@test.kz",
      passwordHash,
      role: UserRole.DOCTOR
    }
  });

  // --- Clinics ---
  const clinic = await prisma.clinic.create({
    data: {
      name: "Городская поликлиника №5",
      city: "Алматы",
      address: "ул. Абая 120, Алматы",
      bin: "990140001234",
      phone: "+77273000005"
    }
  });

  const clinic2 = await prisma.clinic.create({
    data: {
      name: "Halyk MedCare Clinic №1",
      city: "Алматы",
      address: "пр. Аль-Фараби 101/3, Алматы",
      bin: "990140009999",
      phone: "+77272356901"
    }
  });

  // --- Doctor Profiles ---
  await prisma.doctorProfile.create({
    data: {
      userId: doctor.id,
      clinicId: clinic.id,
      specialization: "Терапевт",
      roomNumber: "214",
      scheduleText: "Пн-Пт 09:00-17:00"
    }
  });

  await prisma.doctorProfile.create({
    data: {
      userId: doctor2.id,
      clinicId: clinic2.id,
      specialization: "Кардиолог",
      roomNumber: "305",
      scheduleText: "Пн-Пт 10:00-18:00"
    }
  });

  // --- Appointments with various statuses ---
  const now = new Date();
  const appointmentDate = (dayOffset: number, hour: number, minute = 0) => {
    const date = new Date(now);
    date.setDate(date.getDate() + dayOffset);
    date.setHours(hour, minute, 0, 0);
    return date;
  };

  // 1. PENDING — завтра
  await prisma.appointment.create({
    data: {
      patientId: patient.id,
      doctorId: doctor.id,
      clinicId: clinic.id,
      appointmentDate: appointmentDate(1, 9),
      complaint: "Температура, боль в горле, слабость",
      status: AppointmentStatus.PENDING
    }
  });

  // 2. CONFIRMED — послезавтра
  await prisma.appointment.create({
    data: {
      patientId: patient.id,
      doctorId: doctor.id,
      clinicId: clinic.id,
      appointmentDate: appointmentDate(3, 14),
      complaint: "Плановый осмотр, общее недомогание",
      status: AppointmentStatus.CONFIRMED
    }
  });

  // 3. RESCHEDULED — через 5 дней
  await prisma.appointment.create({
    data: {
      patientId: patient.id,
      doctorId: doctor2.id,
      clinicId: clinic2.id,
      appointmentDate: appointmentDate(5, 11),
      complaint: "Боль в грудной клетке, учащённое сердцебиение",
      status: AppointmentStatus.RESCHEDULED
    }
  });

  // 4. COMPLETED — 7 дней назад, с назначением
  const completedAppointment = await prisma.appointment.create({
    data: {
      patientId: patient.id,
      doctorId: doctor.id,
      clinicId: clinic.id,
      appointmentDate: appointmentDate(-7, 10),
      complaint: "ОРВИ, насморк, кашель",
      status: AppointmentStatus.COMPLETED
    }
  });

  // Add prescription for the completed appointment
  const prescription = await prisma.prescription.create({
    data: {
      appointmentId: completedAppointment.id,
      patientId: patient.id,
      doctorId: doctor.id,
      diagnosis: "ОРВИ средней степени тяжести",
      rawText: "Диагноз: ОРВИ. Рекомендовано: постельный режим, обильное питьё, симптоматическое лечение.",
      doctorComment: "Избегать переохлаждения. Повторный приём через 10 дней при необходимости.",
      status: PrescriptionStatus.ACTIVE
    }
  });

  await prisma.prescriptionMedicine.createMany({
    data: [
      {
        prescriptionId: prescription.id,
        medicineName: "Парацетамол 500 мг",
        dosage: "500 мг",
        frequency: "3 раза в день",
        duration: "5 дней",
        instruction: "Принимать после еды",
        quantityNeeded: 15,
        activeSubstance: "paracetamol"
      },
      {
        prescriptionId: prescription.id,
        medicineName: "Амоксициллин 500 мг",
        dosage: "500 мг",
        frequency: "2 раза в день",
        duration: "7 дней",
        instruction: "Принимать строго по часам",
        quantityNeeded: 14,
        activeSubstance: "amoxicillin"
      }
    ]
  });

  // 5. CANCELLED — 3 дня назад
  await prisma.appointment.create({
    data: {
      patientId: patient.id,
      doctorId: doctor2.id,
      clinicId: clinic2.id,
      appointmentDate: appointmentDate(-3, 15),
      complaint: "Головная боль, головокружение",
      status: AppointmentStatus.CANCELLED
    }
  });

  // --- Market Products ---
  await prisma.marketProduct.createMany({
    data: [
      {
        title: "Амоксициллин 500 мг",
        activeSubstance: "amoxicillin",
        dosage: "500 мг",
        form: "Капсулы",
        manufacturer: "Santo",
        price: 1850,
        stock: 42,
        pharmacyName: "Halyk Pharmacy",
        productUrl: "https://halyk-market.example/products/amoxicillin-500"
      },
      {
        title: "Ибупрофен 200 мг",
        activeSubstance: "ibuprofen",
        dosage: "200 мг",
        form: "Таблетки",
        manufacturer: "Nobel",
        price: 920,
        stock: 65,
        pharmacyName: "Europharma",
        productUrl: "https://halyk-market.example/products/ibuprofen-200"
      },
      {
        title: "Парацетамол 500 мг",
        activeSubstance: "paracetamol",
        dosage: "500 мг",
        form: "Таблетки",
        manufacturer: "Химфарм",
        price: 540,
        stock: 110,
        pharmacyName: "Halyk Pharmacy",
        productUrl: "https://halyk-market.example/products/paracetamol-500"
      },
      {
        title: "Лоратадин 10 мг",
        activeSubstance: "loratadine",
        dosage: "10 мг",
        form: "Таблетки",
        manufacturer: "Santo",
        price: 1150,
        stock: 38,
        pharmacyName: "Аптека 24",
        productUrl: "https://halyk-market.example/products/loratadine-10"
      },
      {
        title: "Азитромицин 500 мг",
        activeSubstance: "azithromycin",
        dosage: "500 мг",
        form: "Таблетки",
        manufacturer: "Nobel",
        price: 2440,
        stock: 21,
        pharmacyName: "Europharma",
        productUrl: "https://halyk-market.example/products/azithromycin-500"
      },
      {
        title: "Спрей для горла",
        activeSubstance: "benzydamine",
        dosage: "0.15%",
        form: "Спрей",
        manufacturer: "World Medicine",
        price: 2150,
        stock: 33,
        pharmacyName: "Halyk Pharmacy",
        productUrl: "https://halyk-market.example/products/throat-spray"
      },
      {
        title: "Витамин C",
        activeSubstance: "ascorbic-acid",
        dosage: "500 мг",
        form: "Таблетки",
        manufacturer: "Doppelherz",
        price: 1680,
        stock: 74,
        pharmacyName: "Аптека 24",
        productUrl: "https://halyk-market.example/products/vitamin-c"
      },
      {
        title: "Цетиризин 10 мг",
        activeSubstance: "cetirizine",
        dosage: "10 мг",
        form: "Таблетки",
        manufacturer: "Teva",
        price: 1320,
        stock: 46,
        pharmacyName: "Europharma",
        productUrl: "https://halyk-market.example/products/cetirizine-10"
      }
    ]
  });

  console.log("✅ Seed complete:");
  console.log("   Patient: patient@test.kz / 123456 / IIN 920815350112");
  console.log("   Doctor:  doctor@test.kz  / 123456");
  console.log("   Doctor2: doctor2@test.kz / 123456");
  console.log("   Appointments: PENDING, CONFIRMED, RESCHEDULED, COMPLETED (with Rx), CANCELLED");
}

main()
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
