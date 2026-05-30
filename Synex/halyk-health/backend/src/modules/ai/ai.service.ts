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

async function parseWithQwen(rawText: string): Promise<ParsedPrescription> {
  const apiUrl =
    process.env.QWEN_API_URL || "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions";

  const response = await fetch(apiUrl, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${process.env.QWEN_API_KEY}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      model: "qwen3",
      messages: [
        {
          role: "system",
          content:
            "Ты медицинский AI-агент для Halyk Health. Не ставь диагноз и не назначай лечение. Только структурируй назначение врача, объясняй простым языком, выделяй лекарства, дозировки, частоту и длительность приема. Верни только JSON."
        },
        {
          role: "user",
          content: `Разбери назначение врача и верни JSON с полями summary, disclaimer, medicines. Текст: ${rawText}`
        }
      ],
      temperature: 0.2,
      response_format: { type: "json_object" }
    })
  });

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
    const parsed = JSON.parse(content) as Partial<ParsedPrescription>;

    return {
      summary: parsed.summary || "Назначение структурировано AI-агентом.",
      disclaimer: AI_DISCLAIMER,
      medicines: Array.isArray(parsed.medicines)
        ? parsed.medicines.map((medicine) => ({
            medicineName: String(medicine.medicineName || ""),
            dosage: String(medicine.dosage || ""),
            frequency: String(medicine.frequency || ""),
            duration: String(medicine.duration || ""),
            instruction: String(medicine.instruction || ""),
            quantityNeeded: Number(medicine.quantityNeeded || 1),
            activeSubstance: String(medicine.activeSubstance || "").toLowerCase()
          }))
        : []
    };
  } catch (error) {
    throw new HttpError(502, "Qwen API returned invalid JSON", error);
  }
}

