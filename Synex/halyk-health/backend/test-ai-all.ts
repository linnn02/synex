import { validatePrescription, explainPrescription, generateDemandReport } from "./src/modules/ai/ai.service";
import * as dotenv from "dotenv";
dotenv.config();

async function run() {
  try {
    console.log("=== VALIDATE ===");
    const val = await validatePrescription("Амоксициллин 500 мг 3 раза в день 7 дней");
    console.log(JSON.stringify(val, null, 2));

    console.log("=== EXPLAIN ===");
    const exp = await explainPrescription({
      diagnosis: "Инфекция",
      medicines: [{medicineName: "Амоксициллин", dosage: "500 мг"}]
    });
    console.log(exp);

    console.log("=== REPORT ===");
    const rep = await generateDemandReport(JSON.stringify({
      recentMedicines: ["Амоксициллин"],
      cartProducts: ["Витамин С"]
    }));
    console.log(JSON.stringify(rep, null, 2));

  } catch(e) {
    console.error("Error:", e);
  }
}
run();
