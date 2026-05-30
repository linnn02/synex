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
};

export type ParsedPrescription = {
  summary: string;
  disclaimer: string;
  medicines: ParsedMedicine[];
};

export async function parsePrescription(rawText: string): Promise<ParsedPrescription> {
  if (isOllamaProvider()) {
    return parseWithOllama(rawText);
  }

  if (!process.env.QWEN_API_KEY) {
    return mockQwenParse(rawText);
  }

  return parseWithQwen(rawText);
}

function mockQwenParse(rawText: string): ParsedPrescription {
  const normalized = rawText.toLowerCase();
  const hasAmoxicillin = normalized.includes("амоксициллин") || normalized.includes("amoxicillin");
  const hasIbuprofen = normalized.includes("ибупрофен") || normalized.includes("ibuprofen");

  if (hasAmoxicillin || hasIbuprofen) {
    return {
      summary:
        "Назначение включает антибиотик курсом на 7 дней и жаропонижающее средство при необходимости.",
      disclaimer: AI_DISCLAIMER,
      medicines: [
        {
          medicineName: "Амоксициллин",
          dosage: "500 мг",
          frequency: "3 раза в день",
          duration: "7 дней",
          instruction: "После еды",
          quantityNeeded: 21,
          activeSubstance: "amoxicillin"
        },
        {
          medicineName: "Ибупрофен",
          dosage: "200 мг",
          frequency: "При температуре",
          duration: "По необходимости",
          instruction: "Не превышать дозировку, указанную врачом",
          quantityNeeded: 1,
          activeSubstance: "ibuprofen"
        }
      ]
    };
  }

  return {
    summary:
      "ИИ-агент структурировал назначение врача. Проверьте детали приема у врача, если часть текста назначения неясна.",
    disclaimer: AI_DISCLAIMER,
    medicines: []
  };
}

function isOllamaProvider() {
  const provider = process.env.QWEN_PROVIDER?.toLowerCase();
  const apiUrl = process.env.QWEN_API_URL?.toLowerCase() || "";
  return provider === "ollama" || apiUrl.includes("11434") || apiUrl.includes("/api/chat");
}

function buildMessages(rawText: string) {
  return [
    {
      role: "system",
      content:
        "Ты медицинский AI-агент для Halyk Health. Не ставь диагноз и не назначай лечение. Только структурируй назначение врача, объясняй простым языком, выделяй лекарства, дозировки, частоту и длительность приема. Верни только валидный JSON без markdown."
    },
    {
      role: "user",
      content: `Верни JSON строго такого вида: {"summary":"...","disclaimer":"...","medicines":[{"medicineName":"...","dosage":"...","frequency":"...","duration":"...","instruction":"...","quantityNeeded":1,"activeSubstance":"..."}]}. activeSubstance верни латиницей в виде международного названия или slug, например amoxicillin, ibuprofen, paracetamol. quantityNeeded посчитай как количество приемов за курс, если это явно возможно. Текст назначения врача: ${rawText}`
    }
  ];
}

function extractJsonObject(content: string) {
  const withoutThinking = content
    .replace(/<think>[\s\S]*?<\/think>/gi, "")
    .replace(/```json/gi, "")
    .replace(/```/g, "")
    .trim();
  const start = withoutThinking.indexOf("{");
  const end = withoutThinking.lastIndexOf("}");

  if (start === -1 || end === -1 || end <= start) {
    throw new Error("No JSON object found in AI response");
  }

  return withoutThinking.slice(start, end + 1);
}

function normalizeParsedPrescription(parsed: Partial<ParsedPrescription>): ParsedPrescription {
  return {
    summary: parsed.summary || "Назначение структурировано AI-агентом.",
    disclaimer: AI_DISCLAIMER,
    medicines: Array.isArray(parsed.medicines)
      ? parsed.medicines
          .map((medicine) => normalizeParsedMedicine(medicine))
          .filter((medicine) => medicine.medicineName && medicine.activeSubstance)
      : []
  };
}

function normalizeParsedMedicine(medicine: ParsedMedicine): ParsedMedicine {
  const medicineName = String(medicine.medicineName || "").trim();
  const dosage = String(medicine.dosage || "").trim();
  const frequency = String(medicine.frequency || "").trim();
  const duration = String(medicine.duration || "").trim();
  const instruction = String(medicine.instruction || "").trim();
  const activeSubstance = normalizeActiveSubstance(
    String(medicine.activeSubstance || medicineName).trim().toLowerCase()
  );
  const quantityNeeded = normalizeQuantityNeeded(Number(medicine.quantityNeeded || 1), frequency, duration);

  return {
    medicineName,
    dosage,
    frequency,
    duration,
    instruction,
    quantityNeeded,
    activeSubstance
  };
}

function normalizeActiveSubstance(activeSubstance: string) {
  const normalized = activeSubstance.toLowerCase().trim();
  const knownMap: Record<string, string> = {
    "амоксициллин": "amoxicillin",
    "amoxicillin": "amoxicillin",
    "ибупрофен": "ibuprofen",
    "ibuprofen": "ibuprofen",
    "парацетамол": "paracetamol",
    "paracetamol": "paracetamol",
    "лоратадин": "loratadine",
    "loratadine": "loratadine",
    "цетиризин": "cetirizine",
    "cetirizine": "cetirizine",
    "азитромицин": "azithromycin",
    "azithromycin": "azithromycin",
    "аскорбиновая кислота": "ascorbic-acid",
    "витамин c": "ascorbic-acid",
    "vitamin c": "ascorbic-acid",
    "ascorbic acid": "ascorbic-acid",
    "бензидамин": "benzydamine",
    "benzydamine": "benzydamine",
    "эналаприл": "enalapril",
    "enalapril": "enalapril"
  };

  return knownMap[normalized] || normalized.replace(/\s+/g, "-");
}

function normalizeQuantityNeeded(quantityNeeded: number, frequency: string, duration: string) {
  const normalizedScheduleText = `${frequency} ${duration}`.toLowerCase();

  if (
    normalizedScheduleText.includes("необходим") ||
    normalizedScheduleText.includes("температур") ||
    normalizedScheduleText.includes("по мере")
  ) {
    return 1;
  }

  if (quantityNeeded > 1) {
    return Math.round(quantityNeeded);
  }

  const durationDays = duration.match(/\d+/)?.[0];
  const frequencyCount = frequency.match(/\d+/)?.[0];

  if (durationDays && frequencyCount) {
    return Number(durationDays) * Number(frequencyCount);
  }

  return 1;
}

async function parseWithOllama(rawText: string): Promise<ParsedPrescription> {
  const apiUrl = process.env.QWEN_API_URL || "http://127.0.0.1:11434/api/chat";
  const model = process.env.QWEN_MODEL || "qwen3:latest";
  const timeoutMs = Number(process.env.QWEN_TIMEOUT_MS || 60000);
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);

  let response: Response;
  try {
    response = await fetch(apiUrl, {
      method: "POST",
      signal: controller.signal,
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        model,
        messages: buildMessages(rawText),
        stream: false,
        format: "json",
        think: false,
        options: {
          temperature: 0.1
        }
      })
    });
  } catch (error) {
    throw new HttpError(502, "Local Ollama Qwen request failed or timed out", error);
  } finally {
    clearTimeout(timeout);
  }

  if (!response.ok) {
    throw new HttpError(502, "Local Ollama Qwen request failed", await response.text());
  }

  const data = (await response.json()) as {
    message?: { content?: string };
    response?: string;
  };

  const content = data.message?.content || data.response;
  if (!content) {
    throw new HttpError(502, "Local Ollama Qwen returned empty content");
  }

  try {
    return normalizeParsedPrescription(JSON.parse(extractJsonObject(content)) as Partial<ParsedPrescription>);
  } catch (error) {
    throw new HttpError(502, "Local Ollama Qwen returned invalid JSON", error);
  }
}

async function parseWithQwen(rawText: string): Promise<ParsedPrescription> {
  const apiUrl =
    process.env.QWEN_API_URL || "https://dashscope-intl.aliyuncs.com/compatible-mode/v1/chat/completions";
  const model = process.env.QWEN_MODEL || "qwen3.6-plus";
  const timeoutMs = Number(process.env.QWEN_TIMEOUT_MS || 20000);
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);

  let response: Response;
  try {
    response = await fetch(apiUrl, {
      method: "POST",
      signal: controller.signal,
      headers: {
        Authorization: `Bearer ${process.env.QWEN_API_KEY}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        model,
        messages: buildMessages(rawText),
        temperature: 0.2,
        response_format: { type: "json_object" }
      })
    });
  } catch (error) {
    throw new HttpError(502, "Qwen API request failed or timed out", error);
  } finally {
    clearTimeout(timeout);
  }

  if (!response.ok) {
    throw new HttpError(502, "Qwen API request failed", await response.text());
  }

  const data = (await response.json()) as {
    choices?: Array<{ message?: { content?: string } }>;
    output_text?: string;
  };

  const content = data.choices?.[0]?.message?.content || data.output_text;
  if (!content) {
    throw new HttpError(502, "Qwen API returned empty content");
  }

  try {
    return normalizeParsedPrescription(JSON.parse(extractJsonObject(content)) as Partial<ParsedPrescription>);
  } catch (error) {
    throw new HttpError(502, "Qwen API returned invalid JSON", error);
  }
}
