import { DoubaoAIService } from "./doubao/DoubaoAIService";
import { IAIService } from "./interface/IAIService";

export enum AIType {
  DOUBAO,
  GEMINI
}

export class AIServiceFactory {
  public static create(type:AIType) :IAIService| null {
    switch (type) {
      case AIType.DOUBAO :
        return new DoubaoAIService();
      case AIType.GEMINI:
          return null;
    }
  }

}