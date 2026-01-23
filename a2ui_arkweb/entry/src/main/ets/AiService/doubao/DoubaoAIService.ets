import { IAIService } from "../interface/IAIService";
import { http } from "@kit.NetworkKit";

export class DoubaoAIService implements IAIService {
  // 用于语音识别的访问 KEY
  private readonly appid ='';
  private readonly token= '';
  private readonly DOUBAO_STT_URL = "";



  async recognizeTask(filePath:string) :Promise<http.HttpResponse | undefined> {

  }
  async recognizeMode(filePath:string) :Promise<string> {

  }

  speechToText(audioFilePath: string): Promise<String> {
    return await
  }
}