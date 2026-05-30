import { AI_DISCLAIMER } from "../../common/constants";
import { HttpError } from "../../common/http-error";

export type ParsedMedicine = {
  medicineName: string;
  dosage: string;
  frequency: string;
  duration: string;
  instruction: string;
  quantityNeeded: number;
  activeSubstance: string;
  notes?: string;
};

export type ParsedPrescription = {
  diagnosis?: string;
  summary: string;
  disclaimer: string;
  doctorComment?: string;
  medicines: ParsedMedicine[];
};

export type PrescriptionValidation = {
  isComplete: boolean;
  warnings: string[];
  suggestions: string[];
};

export type DemandReport = {
  frequentlyPrescribed: string[];
  cartLeaders: string[];
  outOfStockDemand: string[];
  popularAlternatives: string[];
  demandForecast: string;
  businessSummary: string;
};

export async function parsePrescription(rawText: string): Promise<ParsedPrescription> {
  const result = await runAiTask("parse", rawText);
  return normalizeParsedPrescription(result);
}

export async function validatePrescription(rawText: string): Promise<PrescriptionValidation> {
  const result = await runAiTask("validate", rawText);
  return {
    isComplete: !!result.isComplete,
    warnings: Array.isArray(result.warnings) ? result.warnings : [],
    suggestions: Array.isArray(result.suggestions) ? result.suggestions : []
  };
}

export async function explainPrescription(prescription: any): Promise<string> {
  const text = typeof prescription === "string" ? prescription : JSON.stringify(prescription);
  const result = await runAiTask("explain", text);
  return result.explanation || result.summary || "Назначение объяснено AI-агентом.";
}

export async function generateDemandReport(dataJson: string): Promise<DemandReport> {
  const result = await runAiTask("demand-report", dataJson);
  return {
    frequentlyPrescribed: result.frequentlyPrescribed || [],
    cartLeaders: result.cartLeaders || [],
    outOfStockDemand: result.outOfStockDemand || [],
    popularAlternatives: result.popularAlternatives || [],
    demandForecast: result.demandForecast || "Нет данных для прогноза",
    businessSummary: result.businessSummary || "Отчет сформирован"
  };
}

async function runAiTask(task: string, input: string): Promise<any> {
  if (isOllamaProvider()) {
    return runWithOllama(task, input);
  }

  if (!process.env.QWEN_API_KEY) {
    return mockAiResponse(task, input);
  }

  return runWithQwen(task, input);
}

function mockAiResponse(task: string, input: string): any {
  if (task === "parse") {
    return mockQwenParse(input);
  }
  if (task === "validate") {
    return {
      isComplete: false,
      warnings: ["Не указана длительность приема для одного из препаратов"],
      suggestions: ["Уточните у пациента, на какой срок врач назначил препарат"]
    };
  }
  if (task === "explain") {
    return {
      explanation: "Вам назначено комбинированное лечение: антибиотик для борьбы с инфекцией и противовоспалительное средство. Важно пропить курс антибиотика до конца, даже если станет лучше."
    };
  }
  if (task === "demand-report") {
    return {
      frequentlyPrescribed: ["Парацетамол", "Ибупрофен"],
      cartLeaders: ["Витамин С", "Аква Марис"],
      outOfStockDemand: ["Цетиризин"],
      popularAlternatives: ["Лоратадин вместо Цетиризина"],
      demandForecast: "Ожидается рост спроса на противовирусные средства в ближайшую неделю на 15%.",
      businessSummary: "Рынок стабилен, фокус на сезонные препараты."
    };
  }
  return {};
}

function buildMessages(task: string, input: string) {
  let systemPrompt =
    "Ты медицинский AI-агент для Halyk Health. Не ставь диагноз и не назначай лечение. Обязательно добавляй дисклеймер: '" + AI_DISCLAIMER + "'.";
  let userPrompt = "";

  switch (task) {
    case "parse":
      systemPrompt += " Структурируй назначение врача в JSON.";
      userPrompt = `Верни JSON строго такого вида: {"diagnosis":"...","summary":"...","doctorComment":"...","medicines":[{"medicineName":"...","dosage":"...","frequency":"...","duration":"...","instruction":"...","quantityNeeded":1,"activeSubstance":"...","notes":"..."}]}. activeSubstance верни латиницей. Текст: ${input}`;
      break;
    case "validate":
      systemPrompt += " Проверь полноту назначения (лекарство, дозировка, частота, длительность, инструкция).";
      userPrompt = `Верни JSON строго такого вида: {"isComplete":true/false,"warnings":["..."],"suggestions":["..."]}. Текст: ${input}`;
      break;
    case "explain":
      systemPrompt += " Объясни назначение пациенту простым человеческим языком.";
      userPrompt = `Верни JSON строго такого вида: {"explanation":"..."}. Назначение: ${input}`;
      break;
    case "demand-report":
      systemPrompt += " Сформируй аналитический отчет по спросу для бизнеса на основе данных.";
      userPrompt = `Верни JSON строго такого вида: {"frequentlyPrescribed":["..."],"cartLeaders":["..."],"outOfStockDemand":["..."],"popularAlternatives":["..."],"demandForecast":"...","businessSummary":"..."}. Данные: ${input}`;
      break;
    default:
      userPrompt = input;
  }

  return [
    { role: "system", content: systemPrompt },
    { role: "user", content: userPrompt }
  ];
}

async function runWithOllama(task: string, input: string): Promise<any> {
  const apiUrl = process.env.QWEN_API_URL || "http://127.0.0.1:11434/api/chat";
  const model = process.env.QWEN_MODEL || "qwen3:latest";
  
  const response = await fetch(apiUrl, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      model,
      messages: buildMessages(task, input),
      stream: false,
      format: "json",
      options: { temperature: 0.1 }
    })
  });

  if (!response.ok) throw new HttpError(502, "Ollama task failed");
  const data = await response.json();
  const content = data.message?.content || data.response;
  return JSON.parse(extractJsonObject(content));
}

async function runWithQwen(task: string, input: string): Promise<any> {
  const apiUrl = process.env.QWEN_API_URL || "https://dashscope-intl.aliyuncs.com/compatible-mode/v1/chat/completions";
  const model = process.env.QWEN_MODEL || "qwen3.6-plus";

  const response = await fetch(apiUrl, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${process.env.QWEN_API_KEY}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      model,
      messages: buildMessages(task, input),
      temperature: 0.2,
      response_format: { type: "json_object" }
    })
  });

  if (!response.ok) throw new HttpError(502, "Qwen task failed");
  const data = await response.json();
  const content = data.choices?.[0]?.message?.content;
  return JSON.parse(extractJsonObject(content));
}

function mockQwenParse(rawText: string): ParsedPrescription {
  const normalized = rawText.toLowerCase();
  const hasAmoxicillin = normalized.includes("амоксициллин");
  
  return {
    diagnosis: "ОРВИ" + (hasAmoxicillin ? " с подозрением на бактериальную инфекцию" : ""),
    summary: "Назначено симптоматическое лечение" + (hasAmoxicillin ? " и антибиотик" : ""),
    disclaimer: AI_DISCLAIMER,
    medicines: hasAmoxicillin ? [
      {
        medicineName: "Амоксициллин",
        dosage: "500 мг",
        frequency: "3 раза в день",
        duration: "7 дней",
        instruction: "После еды",
        quantityNeeded: 21,
        activeSubstance: "amoxicillin"
      }
    ] : []
  };
}

function isOllamaProvider() {
  const provider = process.env.QWEN_PROVIDER?.toLowerCase();
  return provider === "ollama" || !process.env.QWEN_API_KEY;
}

function extractJsonObject(content: string) {
  const cleaned = content.replace(/```json/gi, "").replace(/```/g, "").trim();
  const start = cleaned.indexOf("{");
  const end = cleaned.lastIndexOf("}");
  if (start === -1 || end === -1) return "{}";
  return cleaned.slice(start, end + 1);
}

function normalizeParsedPrescription(parsed: any): ParsedPrescription {
  return {
    diagnosis: parsed.diagnosis,
    summary: parsed.summary || "Назначение структурировано AI.",
    disclaimer: AI_DISCLAIMER,
    doctorComment: parsed.doctorComment,
    medicines: Array.isArray(parsed.medicines) 
      ? parsed.medicines.map(normalizeParsedMedicine)
      : []
  };
}

function normalizeParsedMedicine(medicine: any): ParsedMedicine {
  const medicineName = String(medicine.medicineName || "").trim();
  const frequency = String(medicine.frequency || "").trim();
  const duration = String(medicine.duration || "").trim();

  return {
    medicineName,
    dosage: String(medicine.dosage || "").trim(),
    frequency,
    duration,
    instruction: String(medicine.instruction || "").trim(),
    activeSubstance: (medicine.activeSubstance || medicineName).toLowerCase().trim().replace(/\s+/g, "-"),
    quantityNeeded: normalizeQuantityNeeded(Number(medicine.quantityNeeded || 1), frequency, duration),
    notes: medicine.notes
  };
}

function normalizeQuantityNeeded(quantityNeeded: number, frequency: string, duration: string) {
  if (quantityNeeded > 1) return Math.round(quantityNeeded);
  const d = parseInt(duration.match(/\d+/)?.[0] || "1");
  const f = parseInt(frequency.match(/\d+/)?.[0] || "1");
  return d * f;
}
