import { IAIService } from "../interface/IAIService";
import { http } from "@kit.NetworkKit";

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
      Logger.error(TAG, 'Either fileUrl or filePath must be provided.');
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
      Logger.info(TAG, 'Sending recognition request...');
      const response = await httpRequest.request(this.DOUBAO_STT_URL, {
        method: http.RequestMethod.POST,
        header: headers,
        extraData: JSON.stringify(requestPayload)
      });

      // Log response headers
      if (response.header['x-api-status-code']) {
        Logger.info(TAG, `Recognize task response header X-Api-Status-Code: ${response.header['x-api-status-code']}`);
        Logger.info(TAG, `Recognize task response header X-Api-Message: ${response.header['x-api-message']}`);
        Logger.info(TAG, `Recognize task response header X-Tt-Logid: ${response.header["x-tt-logid"]}`);
        Logger.info(TAG, `Recognize task response content is: ${response.result}`);
      } else {
        Logger.error(TAG, `Recognize task failed. Response headers: ${JSON.stringify(response.header)}`);
      }

      return response;
    } catch (err) {
      Logger.error(TAG, `HTTP request failed: ${JSON.stringify(err)}`);
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
  async recognizeMode(filePath: string): Promise<string> {
    const startTime = Date.now();
    Logger.info(TAG, `${new Date().toISOString()} START!`);

    try {
      const recognizeResponse: http.HttpResponse | undefined = await this.recognizeTask(filePath);
      if (recognizeResponse == undefined) {
        Logger.info(TAG, `识别失败`);
        return "";
      }
      const code = parseInt(recognizeResponse.header['x-api-status-code'] as string);
      const logid = recognizeResponse.header['x-tt-logid'] as string;

      if (code === VoiceRecognizeErrCode.SUCCESS) { // Task finished successfully
        let json_result: IResponseText = JSON.parse(recognizeResponse.result as string);
        const resultJson = JSON.stringify(JSON.parse(recognizeResponse.result as string), null, 4);

        // Save the result to a file in the app's cache directory
        let ctx = GlobalContext.getContext().getObject(Constants.MAIN_ABILITY_CONTEXT) as common.UIAbilityContext;
        const cacheDir = ctx.getApplicationContext().cacheDir;
        const resultFilePath = `${cacheDir}/result.json`;

        const resultFile =
          await fs.open(resultFilePath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
        await fs.write(resultFile.fd, resultJson);
        await fs.close(resultFile.fd);

        Logger.info(TAG, `${new Date().toISOString()} SUCCESS! Result saved to ${resultFilePath}`);
        const duration = (Date.now() - startTime) / 1000;
        Logger.info(TAG, `语音识别运行耗时: ${duration.toFixed(6)} 秒`);
        Logger.info(TAG, `语音识别内容: ${json_result?.result?.text}`);
        return json_result?.result?.text;
      } else if (code !== 20000001 && code !== 20000002) { // Task failed
        Logger.error(TAG, `${new Date().toISOString()} FAILED! code: ${code}, logid: ${logid}`);
        Logger.error(TAG, `Headers: ${JSON.stringify(recognizeResponse.header)}`);
      } else { // Task is still processing
        Logger.info(TAG, `Task is still processing. Code: ${code}`);
      }
    } catch (error) {
      Logger.error(TAG, `An error occurred in recognizeMode: ${JSON.stringify(error)}`);
    }
    return "";
  }

  async speechToText(audioFilePath: string): Promise<string> {
    Logger.info(TAG, `Starting speech-to-text for: ${audioFilePath}`);

    return await this.recognizeMode(audioFilePath);
  }

}
