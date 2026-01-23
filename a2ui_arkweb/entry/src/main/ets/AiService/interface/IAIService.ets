import { common } from "@kit.AbilityKit";

export interface IAIService {
  speechToText(audioFilePath: string,  context:common.Context):Promise<string>;
}