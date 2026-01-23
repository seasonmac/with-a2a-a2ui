export interface IAIService {
  speechToText(audioFilePath: string):Promise<String>;
}