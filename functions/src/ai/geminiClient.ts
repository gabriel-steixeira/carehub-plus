/*
 * CareHub Plus — Functions / Cliente do Gemini
 *
 * Único ponto do backend que chama a Gemini Developer API (Interactions).
 * Porta do GeminiService do app: mesmo endpoint, mesmas tentativas em falha
 * temporária e as mesmas mensagens de erro, para a pessoa ver o mesmo texto
 * de antes. A chave vem do Secret Manager e nunca sai do servidor.
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

const INTERACTIONS_URL = "https://generativelanguage.googleapis.com/v1beta/interactions";
const TIMEOUT_MS = 35_000;
const MAX_ATTEMPTS = 2;

export type Persona = "cora" | "toke";

interface PersonaWords {
  name: string;
  /** "a Cora" / "o Toke" */
  withArticle: string;
  /** "à Cora" / "ao Toke" */
  withContraction: string;
  /** "da Cora" / "do Toke" */
  ofPersona: string;
  /** "para a Cora" / "para o Toke" */
  forPersona: string;
}

const WORDS: Record<Persona, PersonaWords> = {
  cora: {
    name: "Cora",
    withArticle: "a Cora",
    withContraction: "à Cora",
    ofPersona: "da Cora",
    forPersona: "para a Cora",
  },
  toke: {
    name: "Toke",
    withArticle: "o Toke",
    withContraction: "ao Toke",
    ofPersona: "do Toke",
    forPersona: "para o Toke",
  },
};

function capitalize(text: string): string {
  return text.charAt(0).toUpperCase() + text.slice(1);
}

/** Erro conhecido, sem expor a chave nem a resposta bruta da API. */
export class GeminiError extends Error {
  constructor(
    message: string,
    readonly status: number | null = null,
  ) {
    super(message);
    this.name = "GeminiError";
  }

  get isTemporary(): boolean {
    return this.status === null || this.status === 429 || (this.status >= 500 && this.status <= 504);
  }
}

export interface GenerateInput {
  persona: Persona;
  systemInstruction: string;
  input: string;
  temperature: number;
  /** Schema JSON para resposta estruturada; sem ele, a resposta é texto. */
  responseSchema?: Record<string, unknown>;
}

/** Contrato usado pelos cérebros — permite trocar por um dublê nos testes. */
export interface TextGenerator {
  generate(input: GenerateInput): Promise<string>;
}

export interface GeminiClientOptions {
  apiKey: string;
  model: string;
  fetchImpl?: typeof fetch;
  retryDelayMs?: number;
}

export class GeminiClient implements TextGenerator {
  private readonly fetchImpl: typeof fetch;

  constructor(private readonly options: GeminiClientOptions) {
    this.fetchImpl = options.fetchImpl ?? fetch;
  }

  async generate(input: GenerateInput): Promise<string> {
    const words = WORDS[input.persona];
    if (!this.options.apiKey.trim()) {
      throw new GeminiError(`A integração com ${words.withArticle} ainda não foi configurada.`);
    }

    const payload: Record<string, unknown> = {
      model: this.options.model,
      system_instruction: input.systemInstruction,
      input: input.input,
      store: false,
      generation_config: { temperature: input.temperature, thinking_level: "minimal" },
    };
    if (input.responseSchema) {
      payload.response_format = {
        type: "text",
        mime_type: "application/json",
        schema: input.responseSchema,
      };
    }

    const body = await this.postWithRetry(JSON.stringify(payload), words);
    return this.extractText(body, words);
  }

  private async postWithRetry(body: string, words: PersonaWords): Promise<string> {
    let lastError: GeminiError | null = null;

    for (let attempt = 0; attempt < MAX_ATTEMPTS; attempt++) {
      const isLast = attempt === MAX_ATTEMPTS - 1;
      try {
        const response = await this.fetchImpl(INTERACTIONS_URL, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "x-goog-api-key": this.options.apiKey,
          },
          body,
          signal: AbortSignal.timeout(TIMEOUT_MS),
        });

        if (response.ok) return await response.text();

        lastError = this.errorFromStatus(response.status, words);
        if (!lastError.isTemporary || isLast) throw lastError;
      } catch (error) {
        if (error instanceof GeminiError) {
          if (!error.isTemporary || isLast) throw error;
          lastError = error;
        } else if ((error as Error)?.name === "TimeoutError") {
          lastError = new GeminiError("O Gemini demorou para responder. Tente novamente.");
          if (isLast) throw lastError;
        } else {
          lastError = new GeminiError(
            `Não foi possível conectar ${words.withContraction}. Verifique sua internet.`,
          );
          if (isLast) throw lastError;
        }
      }

      await new Promise((resolve) =>
        setTimeout(resolve, (this.options.retryDelayMs ?? 300) * (attempt + 1)),
      );
    }

    throw lastError ?? new GeminiError(`Não foi possível consultar ${words.withArticle}.`);
  }

  private extractText(responseBody: string, words: PersonaWords): string {
    const noAnswer = new GeminiError(
      `${capitalize(words.withArticle)} não conseguiu formular uma resposta segura.`,
    );

    let decoded: { steps?: unknown[] };
    try {
      decoded = JSON.parse(responseBody) as { steps?: unknown[] };
    } catch {
      throw noAnswer;
    }

    const text = (decoded.steps ?? [])
      .filter((step): step is { type?: string; content?: unknown[] } => typeof step === "object" && step !== null)
      .filter((step) => step.type === "model_output")
      .flatMap((step) => step.content ?? [])
      .filter((part): part is { type?: string; text?: unknown } => typeof part === "object" && part !== null)
      .filter((part) => part.type === "text" && typeof part.text === "string")
      .map((part) => part.text as string)
      .join("\n")
      .trim();

    if (!text) throw noAnswer;
    return text;
  }

  private errorFromStatus(status: number, words: PersonaWords): GeminiError {
    const subject = capitalize(words.withArticle);
    let message: string;
    if (status === 400) message = `A solicitação enviada ${words.withContraction} não foi aceita.`;
    else if (status === 401 || status === 403) message = `A integração com ${words.withArticle} não está autorizada.`;
    else if (status === 404) message = `O modelo configurado ${words.forPersona} não está disponível.`;
    else if (status === 429) message = `${subject} recebeu muitas solicitações. Aguarde um momento.`;
    else if (status >= 500 && status <= 504) message = `O serviço ${words.ofPersona} está temporariamente indisponível.`;
    else message = `Não foi possível consultar ${words.withArticle}.`;
    return new GeminiError(message, status);
  }
}

/** Turno anterior da conversa, enviado como transcrição. */
export interface ChatTurn {
  role: "user" | "model";
  text: string;
}

const HISTORY_LIMIT = 10;

/** Mesmo formato de transcrição que o app montava. */
export function buildInput(currentMessage: string, history: ChatTurn[], persona: Persona): string {
  const recent = history.filter((turn) => turn.text.trim()).slice(-HISTORY_LIMIT);
  if (recent.length === 0) return currentMessage;

  const transcript = recent
    .map((turn) => `${turn.role === "model" ? WORDS[persona].name : "Cuidador"}: ${turn.text.trim()}`)
    .join("\n");
  return `Conversa anterior:\n${transcript}\n\nMensagem atual do cuidador:\n${currentMessage}\n`;
}
