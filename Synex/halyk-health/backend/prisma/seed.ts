import { PrismaClient, UserRole } from "@prisma/client";
import bcrypt from "bcryptjs";

const prisma = new PrismaClient();

async function main() {
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

  const patient = await prisma.user.create({
    data: {
      fullName: "Айдана Смагулова",
      phone: "+77010000001",
      email: "patient@test.kz",
      passwordHash,
      role: UserRole.PATIENT,
      birthDate: new Date("1994-04-12"),
      address: "Алматы"
    }
  });

  const doctor = await prisma.user.create({
    data: {
      fullName: "Доктор Алия Нурланова",
      phone: "+77010000002",
      email: "doctor@test.kz",
      passwordHash,
      role: UserRole.DOCTOR
    }
  });

  const clinic = await prisma.clinic.create({
    data: {
      name: "Городская поликлиника №5",
      city: "Алматы",
      address: "ул. Абая 120",
      bin: "990140001234",
      phone: "+77273000005"
    }
  });

  await prisma.doctorProfile.create({
    data: {
      userId: doctor.id,
      clinicId: clinic.id,
      specialization: "Терапевт",
      roomNumber: "214",
      scheduleText: "Пн-Пт 09:00-17:00"
    }
  });

  await prisma.appointment.create({
    data: {
      patientId: patient.id,
      doctorId: doctor.id,
      clinicId: clinic.id,
      appointmentDate: new Date(Date.now() + 24 * 60 * 60 * 1000),
      complaint: "Температура, боль в горле, слабость",
      status: "PENDING"
    }
  });

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

  console.log("Seed data ready: patient@test.kz / doctor@test.kz with password 123456");
}

main()
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

