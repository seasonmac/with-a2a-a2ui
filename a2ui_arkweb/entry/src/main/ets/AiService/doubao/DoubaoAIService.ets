import { IAIService } from "../interface/IAIService";
import { http } from "@kit.NetworkKit";
import { http_headers, IAudioData, IRequestPayload, IResponseText, VoiceRecognizeErrCode } from "./ResponseJson";
import Utils from "../../utils/Utils";
import fs from '@ohos.file.fs'
import { hilog } from "@kit.PerformanceAnalysisKit";
import { common } from "@kit.AbilityKit";


const TAG = 'DoubaoAIService';
export class DoubaoAIService implements IAIService {
  // 用于语音识别的访问 KEY
  private readonly appid ='';
  private readonly token= '';
  private readonly DOUBAO_STT_URL = "";

  async recognizeTask(filePath: string): Promise<http.HttpResponse | undefined> {
    const headers: http_headers = {
      "X-Api-App-Key": this.appid,
      "X-Api-Access-Key": this.token,
      "X-Api-Resource-Id": "volc.bigasr.auc_turbo",
      "X-Api-Request-Id": Utils.generateUUID(),
      "X-Api-Sequence": "-1",
      "Content-Type": "application/json"
    };

    let audioData: IAudioData;

    if (fs.accessSync(filePath)) {
      const base64_data = await Utils.fileToBase64(filePath);
      audioData = { "data": base64_data };
    } else {
      hilog.info(0xff00, TAG, '%{public}s,%{public}s', 'Either fileUrl or filePath must be provided.');
      throw new Error("必须提供file_path 其中之一");
    }

    const requestPayload: IRequestPayload = {
      "user": {
        "uid": this.appid
      },
      "audio": audioData,
      "request": {
        "model_name": "bigmodel",
      },
    };

    const httpRequest = http.createHttp();
    try {
      hilog.info(0xff00, TAG, '%{public}s,%{public}s','Sending recognition request...');
      const response = await httpRequest.request(this.DOUBAO_STT_URL, {
        method: http.RequestMethod.POST,
        header: headers,
        extraData: JSON.stringify(requestPayload)
      });

      // Log response headers
      if (response.header['x-api-status-code']) {
        hilog.info(0xff00, TAG, '%{public}s,%{public}s',`Recognize task response header X-Api-Status-Code: ${response.header['x-api-status-code']}`);
        hilog.info(0xff00, TAG, '%{public}s,%{public}s',`Recognize task response header X-Api-Message: ${response.header['x-api-message']}`);
        hilog.info(0xff00, TAG, '%{public}s,%{public}s',`Recognize task response header X-Tt-Logid: ${response.header["x-tt-logid"]}`);
        hilog.info(0xff00, TAG, '%{public}s,%{public}s',`Recognize task response content is: ${response.result}`);
      } else {
        hilog.info(0xff00, TAG, '%{public}s,%{public}s',`Recognize task failed. Response headers: ${JSON.stringify(response.header)}`);
      }

      return response;
    } catch (err) {
      hilog.info(0xff00, TAG, '%{public}s,%{public}s',`HTTP request failed: ${JSON.stringify(err)}`);
    } finally {
      httpRequest.destroy();
    }
    return;
  }

  /**
   * Main function to start the recognition process and handle the result.
   * @param context The application or UI context, needed to get file paths.
   * @param fileUrl Optional URL of the audio file.
   * @param filePath Optional local path of the audio file.
   */
  async recognizeMode(filePath: string,  context:common.Context): Promise<string> {
    const startTime = Date.now();
    hilog.info(0xff00, TAG, '%{public}s,%{public}s',`${new Date().toISOString()} START!`);

    try {
      const recognizeResponse: http.HttpResponse | undefined = await this.recognizeTask(filePath);
      if (recognizeResponse == undefined) {
        hilog.info(0xff00, TAG, '%{public}s,%{public}s',`识别失败`);
        return "";
      }
      const code = parseInt(recognizeResponse.header['x-api-status-code'] as string);
      const logid = recognizeResponse.header['x-tt-logid'] as string;

      if (code === VoiceRecognizeErrCode.SUCCESS) { // Task finished successfully
        let json_result: IResponseText = JSON.parse(recognizeResponse.result as string);
        const resultJson = JSON.stringify(JSON.parse(recognizeResponse.result as string), null, 4);

        // Save the result to a file in the app's cache directory
        const cacheDir = context.getApplicationContext().cacheDir;
        const resultFilePath = `${cacheDir}/result.json`;

        const resultFile =
          await fs.open(resultFilePath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
        await fs.write(resultFile.fd, resultJson);
        await fs.close(resultFile.fd);

        hilog.info(0xff00, TAG, '%{public}s,%{public}s',`${new Date().toISOString()} SUCCESS! Result saved to ${resultFilePath}`);
        const duration = (Date.now() - startTime) / 1000;
        hilog.info(0xff00, TAG, '%{public}s,%{public}s',`语音识别运行耗时: ${duration.toFixed(6)} 秒`);
        hilog.info(0xff00, TAG, '%{public}s,%{public}s',`语音识别内容: ${json_result?.result?.text}`);
        return json_result?.result?.text;
      } else if (code !== 20000001 && code !== 20000002) { // Task failed
        hilog.info(0xff00, TAG, '%{public}s,%{public}s',`${new Date().toISOString()} FAILED! code: ${code}, logid: ${logid}`);
        hilog.info(0xff00, TAG, '%{public}s,%{public}s',`Headers: ${JSON.stringify(recognizeResponse.header)}`);
      } else { // Task is still processing
        hilog.info(0xff00, TAG, '%{public}s,%{public}s',`Task is still processing. Code: ${code}`);
      }
    } catch (error) {
      hilog.info(0xff00, TAG, '%{public}s,%{public}s',`An error occurred in recognizeMode: ${JSON.stringify(error)}`);
    }
    return "";
  }

  async speechToText(audioFilePath: string, context:common.Context): Promise<string> {
    hilog.info(0xff00, TAG, '%{public}s,%{public}s',`Starting speech-to-text for: ${audioFilePath}`);

    return await this.recognizeMode(audioFilePath, context);
  }

}
