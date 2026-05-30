export const swaggerDocument = {
  openapi: "3.0.0",
  info: {
    title: "Halyk Health API",
    version: "0.1.0",
    description:
      "MVP API for patient appointments, doctor prescriptions, Qwen3 AI parsing, pharmacy market, cart, and medication schedule."
  },
  servers: [{ url: "http://localhost:4000/api" }],
  components: {
    securitySchemes: {
      bearerAuth: {
        type: "http",
        scheme: "bearer",
        bearerFormat: "JWT"
      }
    }
  },
  paths: {
    "/auth/login": {
      post: {
        tags: ["Auth"],
        summary: "Login with email and password",
        requestBody: {
          required: true,
          content: {
            "application/json": {
              example: { email: "patient@test.kz", password: "123456" }
            }
          }
        },
        responses: { "200": { description: "JWT token and user profile" } }
      }
    },
    "/auth/register": {
      post: {
        tags: ["Auth"],
        summary: "Register patient or doctor account",
        responses: { "201": { description: "Created user and JWT token" } }
      }
    },
    "/auth/me": {
      get: {
        tags: ["Auth"],
        security: [{ bearerAuth: [] }],
        summary: "Current authenticated user",
        responses: { "200": { description: "User profile" } }
      }
    },
    "/clinics": {
      get: {
        tags: ["Clinics"],
        summary: "List clinics",
        responses: { "200": { description: "Clinic list" } }
      }
    },
    "/clinics/{id}": {
      get: {
        tags: ["Clinics"],
        summary: "Clinic details",
        parameters: [{ name: "id", in: "path", required: true, schema: { type: "string" } }],
        responses: { "200": { description: "Clinic details" } }
      }
    },
    "/clinics/{id}/doctors": {
      get: {
        tags: ["Clinics"],
        summary: "Doctors in clinic",
        parameters: [{ name: "id", in: "path", required: true, schema: { type: "string" } }],
        responses: { "200": { description: "Doctor profile list" } }
      }
    },
    "/appointments": {
      post: {
        tags: ["Appointments"],
        security: [{ bearerAuth: [] }],
        summary: "Create appointment request",
        requestBody: {
          required: true,
          content: {
            "application/json": {
              example: {
                doctorId: "uuid",
                clinicId: "uuid",
                appointmentDate: "2026-06-01T09:00:00.000Z",
                complaint: "Температура и боль в горле"
              }
            }
          }
        },
        responses: { "201": { description: "Created appointment" } }
      }
    },
    "/appointments/my": {
      get: {
        tags: ["Appointments"],
        security: [{ bearerAuth: [] }],
        summary: "Patient appointments",
        responses: { "200": { description: "Appointment list" } }
      }
    },
    "/doctor/appointments": {
      get: {
        tags: ["Doctor"],
        security: [{ bearerAuth: [] }],
        summary: "Doctor appointments",
        responses: { "200": { description: "Appointment list for doctor" } }
      }
    },
    "/appointments/{id}/status": {
      patch: {
        tags: ["Appointments"],
        security: [{ bearerAuth: [] }],
        summary: "Update appointment status",
        parameters: [{ name: "id", in: "path", required: true, schema: { type: "string" } }],
        requestBody: {
          required: true,
          content: { "application/json": { example: { status: "CONFIRMED" } } }
        },
        responses: { "200": { description: "Updated appointment" } }
      }
    },
    "/prescriptions": {
      post: {
        tags: ["Prescriptions"],
        security: [{ bearerAuth: [] }],
        summary: "Doctor creates prescription",
        requestBody: {
          required: true,
          content: {
            "application/json": {
              example: {
                appointmentId: "uuid",
                diagnosis: "ОРВИ",
                rawText:
                  "Амоксициллин 500 мг 3 раза в день 7 дней после еды. Ибупрофен 200 мг при температуре.",
                doctorComment: "Контроль через 3 дня"
              }
            }
          }
        },
        responses: { "201": { description: "Created prescription" } }
      }
    },
    "/prescriptions/my": {
      get: {
        tags: ["Prescriptions"],
        security: [{ bearerAuth: [] }],
        summary: "Patient prescriptions",
        responses: { "200": { description: "Prescription list" } }
      }
    },
    "/prescriptions/{id}": {
      get: {
        tags: ["Prescriptions"],
        security: [{ bearerAuth: [] }],
        summary: "Prescription details",
        parameters: [{ name: "id", in: "path", required: true, schema: { type: "string" } }],
        responses: { "200": { description: "Prescription details" } }
      }
    },
    "/doctor/prescriptions": {
      get: {
        tags: ["Doctor"],
        security: [{ bearerAuth: [] }],
        summary: "Doctor prescriptions",
        responses: { "200": { description: "Prescription list for doctor" } }
      }
    },
    "/prescriptions/{id}/analyze-ai": {
      post: {
        tags: ["Prescriptions"],
        security: [{ bearerAuth: [] }],
        summary: "Analyze prescription with Qwen3 or mock response",
        parameters: [{ name: "id", in: "path", required: true, schema: { type: "string" } }],
        responses: { "200": { description: "AI analyzed prescription" } }
      }
    },
    "/prescriptions/{id}/market-products": {
      get: {
        tags: ["Prescriptions"],
        security: [{ bearerAuth: [] }],
        summary: "Matched market products for prescription medicines",
        parameters: [{ name: "id", in: "path", required: true, schema: { type: "string" } }],
        responses: { "200": { description: "Products grouped by prescription medicine" } }
      }
    },
    "/prescriptions/{id}/schedule": {
      get: {
        tags: ["Prescriptions"],
        security: [{ bearerAuth: [] }],
        summary: "Medication schedule for prescription",
        parameters: [{ name: "id", in: "path", required: true, schema: { type: "string" } }],
        responses: { "200": { description: "Medication schedule" } }
      }
    },
    "/ai/parse-prescription": {
      post: {
        tags: ["AI"],
        security: [{ bearerAuth: [] }],
        summary: "Parse raw prescription text",
        requestBody: {
          required: true,
          content: {
            "application/json": {
              example: {
                rawText:
                  "Амоксициллин 500 мг 3 раза в день 7 дней после еды. Ибупрофен 200 мг при температуре."
              }
            }
          }
        },
        responses: { "200": { description: "Structured AI output" } }
      }
    },
    "/market/products": {
      get: { tags: ["Market"], summary: "List market products", responses: { "200": { description: "Product list" } } }
    },
    "/market/search": {
      get: {
        tags: ["Market"],
        summary: "Search products by medicine name",
        parameters: [{ name: "query", in: "query", schema: { type: "string" } }],
        responses: { "200": { description: "Product list" } }
      }
    },
    "/market/alternatives": {
      get: {
        tags: ["Market"],
        summary: "Search alternatives by active substance",
        parameters: [{ name: "activeSubstance", in: "query", schema: { type: "string" } }],
        responses: { "200": { description: "Product alternatives" } }
      }
    },
    "/market/cart": {
      post: {
        tags: ["Market"],
        security: [{ bearerAuth: [] }],
        summary: "Add product to cart",
        requestBody: {
          required: true,
          content: { "application/json": { example: { productId: "uuid", quantity: 1 } } }
        },
        responses: { "201": { description: "Cart item" } }
      },
      get: {
        tags: ["Market"],
        security: [{ bearerAuth: [] }],
        summary: "Patient cart",
        responses: { "200": { description: "Cart item list" } }
      }
    },
    "/schedule/my": {
      get: {
        tags: ["Schedule"],
        security: [{ bearerAuth: [] }],
        summary: "Patient medication schedule",
        responses: { "200": { description: "Schedule list" } }
      }
    },
    "/schedule/{id}/taken": {
      patch: {
        tags: ["Schedule"],
        security: [{ bearerAuth: [] }],
        summary: "Mark schedule item as taken",
        parameters: [{ name: "id", in: "path", required: true, schema: { type: "string" } }],
        responses: { "200": { description: "Updated schedule item" } }
      }
    },
    "/schedule/{id}/missed": {
      patch: {
        tags: ["Schedule"],
        security: [{ bearerAuth: [] }],
        summary: "Mark schedule item as missed",
        parameters: [{ name: "id", in: "path", required: true, schema: { type: "string" } }],
        responses: { "200": { description: "Updated schedule item" } }
      }
    }
  }
};

