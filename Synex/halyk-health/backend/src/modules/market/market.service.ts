import { MatchType, type PrescriptionMedicine } from "@prisma/client";
import { prisma } from "../../common/prisma";

export async function findProductsByMedicineName(medicineName: string) {
  return prisma.marketProduct.findMany({
    where: {
      OR: [
        { title: { contains: medicineName, mode: "insensitive" } },
        { activeSubstance: { contains: medicineName, mode: "insensitive" } }
      ]
    },
    orderBy: [{ stock: "desc" }, { price: "asc" }]
  });
}

export async function findAlternatives(activeSubstance: string) {
  return prisma.marketProduct.findMany({
    where: {
      activeSubstance: {
        equals: activeSubstance,
        mode: "insensitive"
      }
    },
    orderBy: [{ price: "asc" }, { stock: "desc" }]
  });
}

export async function createMedicineMatches(medicine: PrescriptionMedicine) {
  const products = await prisma.marketProduct.findMany({
    where: {
      OR: [
        { title: { contains: medicine.medicineName, mode: "insensitive" } },
        { activeSubstance: { equals: medicine.activeSubstance, mode: "insensitive" } }
      ]
    }
  });

  await prisma.medicineMatch.deleteMany({
    where: { prescriptionMedicineId: medicine.id }
  });

  if (!products.length) {
    return [];
  }

  await prisma.medicineMatch.createMany({
    data: products.map((product) => {
      const exact = product.title.toLowerCase().includes(medicine.medicineName.toLowerCase());
      const sameActiveSubstance =
        product.activeSubstance.toLowerCase() === medicine.activeSubstance.toLowerCase();

      return {
        prescriptionMedicineId: medicine.id,
        productId: product.id,
        matchType: exact ? MatchType.EXACT : MatchType.ACTIVE_SUBSTANCE,
        confidenceScore: exact ? 0.96 : sameActiveSubstance ? 0.86 : 0.65,
        isAlternative: !exact
      };
    })
  });

  return prisma.medicineMatch.findMany({
    where: { prescriptionMedicineId: medicine.id },
    include: { product: true }
  });
}

