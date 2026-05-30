import { parsePrescription } from "./src/modules/ai/ai.service";

async function run() {
  process.env.QWEN_PROVIDER = "ollama";
  process.env.QWEN_API_URL = "http://127.0.0.1:11434/api/chat";
  process.env.QWEN_MODEL = "qwen3:latest";
  try {
    const res = await parsePrescription("Амоксициллин 500 мг 3 раза в день 7 дней");
    console.log("Success:", JSON.stringify(res, null, 2));
  } catch(e) {
    console.error("Error:", e);
  }
}
run();
