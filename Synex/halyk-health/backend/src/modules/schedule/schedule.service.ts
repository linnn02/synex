import type { PrescriptionMedicine } from "@prisma/client";
import { prisma } from "../../common/prisma";

export function resolveDailyTimes(frequency: string) {
  const normalized = frequency.toLowerCase();

  if (normalized.includes("3")) {
    return [8, 14, 20];
  }

  if (normalized.includes("2")) {
    return [9, 21];
  }

  if (normalized.includes("при температуре") || normalized.includes("необходим")) {
    return [10];
  }

  return [9];
}

export function resolveCourseDays(duration: string) {
  const match = duration.match(/\d+/);
  return match ? Number(match[0]) : 1;
}

export async function createScheduleForMedicine(patientId: string, medicine: PrescriptionMedicine) {
  await prisma.medicationSchedule.deleteMany({
    where: {
      patientId,
      prescriptionMedicineId: medicine.id
    }
  });

  const hours = resolveDailyTimes(medicine.frequency);
  const days = resolveCourseDays(medicine.duration);
  const scheduleData = [];

  for (let day = 0; day < days; day += 1) {
    for (const hour of hours) {
      const takeTime = new Date();
      takeTime.setDate(takeTime.getDate() + day);
      takeTime.setHours(hour, 0, 0, 0);

      scheduleData.push({
        patientId,
        prescriptionMedicineId: medicine.id,
        takeTime
      });
    }
  }

  if (scheduleData.length) {
    await prisma.medicationSchedule.createMany({ data: scheduleData });
  }

  return prisma.medicationSchedule.findMany({
    where: { patientId, prescriptionMedicineId: medicine.id },
    include: { prescriptionMedicine: true },
    orderBy: { takeTime: "asc" }
  });
}

