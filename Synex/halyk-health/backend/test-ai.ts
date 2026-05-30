import { parsePrescription } from "./src/modules/ai/ai.service";
import * as dotenv from "dotenv";
dotenv.config();

async function run() {
  try {
    const res = await parsePrescription("Амоксициллин 500 мг 3 раза в день 7 дней");
    console.log("Success:", JSON.stringify(res, null, 2));
  } catch(e) {
    console.error("Error:", e);
  }
}
run();
