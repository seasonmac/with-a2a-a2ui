// A2UIInArkWeb.ets  (完整单文件)
import { webview } from '@kit.ArkWeb';
import { audio } from '@kit.AudioKit';
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import fs from '@ohos.file.fs';
import Utils, { WavHeaderParams } from '../utils/Utils';
import { AIServiceFactory, AIType } from '../AiService/AIServiceFactory';
import { IAIService } from '../AiService/interface/IAIService';

const TAG = 'FrontEnd';

/* 步骤 3 ： ArkWeb 直接加载本地文件  */
@Component
export struct A2UIInArkWeb {
  // 1.  WebView 控制器
  private controller: webview.WebviewController = new webview.WebviewController();
  // 录音机实例和录音文件路径
  private atManager = abilityAccessCtrl.createAtManager();
  private appContext: common.Context = getContext(this);
  private audioCapturer: audio.AudioCapturer | null = null;
  private audioFilePath: string = '';
  private wavFilePath: string = '';
  private fileDesciptor: number = -1;
  private buffferOffset: number = 0;
  private messageIdCounter: number = 0;
  private PERMISSION: Array<Permissions> =
    ['ohos.permission.MICROPHONE', 'ohos.permission.WRITE_MEDIA', 'ohos.permission.READ_MEDIA',
      'ohos.permission.WRITE_AUDIO', 'ohos.permission.READ_AUDIO'];
  // 3.  用于 UI 的状态
  @State private lastA2UData: string = '';
  @State private msgCount: number = 0;
  private aiService: IAIService = AIServiceFactory.create(AIType.DOUBAO);

  async requestPermissionFn() {
    try {
      this.atManager.requestPermissionsFromUser(this.appContext, this.PERMISSION).then(() => {
        hilog.info(0xff00, TAG, '%{public}s,%{public}s', 'request Permission success!');
      })
    } catch (err) {
      hilog.info(0xff00, TAG, '%{public}s,%{public}s', `request Permission error:${err.code}`);
    }
  }

  schemeMap = new Map([
    ['https://www.locala2uiywh.com/index.html', 'a2ui/index.html'],
    ['https://www.locala2uiywh.com/assets/app.js', 'a2ui/assets/app.js'],
    ['https://www.locala2uiywh.com/hero.png', 'a2ui/hero.png'],
    ['https://www.locala2uiywh.com/hero-dark.png', 'a2ui/hero-dark.png'],
    ['https://www.locala2uiywh.com/agent-webview.js', 'a2ui/agent-webview.js'],
    ['http://localhost:10002/static/shrimpchowmein.jpeg', 'a2ui/image/shrimpchowmein.jpeg'],
    ['http://localhost:10002/static/mapotofu.jpeg', 'a2ui/image/mapotofu.jpeg'],
    ['http://localhost:10002/static/beefbroccoli.jpeg', 'a2ui/image/beefbroccoli.jpeg'],
    ['http://localhost:10002/static/springrolls.jpeg', 'a2ui/image/springrolls.jpeg'],
    ['http://localhost:10002/static/kungpao.jpeg', 'a2ui/image/kungpao.jpeg'],
    // ['http://localhost:10002/.well-known/agent-card.json','a2ui/agent-card.json'],
  ]);
  mimeType = new Map([
    ['a2ui/index.html', 'text/html'],
    ['a2ui/assets/app.js', 'text/javascript'],
    ['a2ui/hero.png', 'image/png'],
    ['a2ui/hero-dark.png', 'image/png'],
    ['a2ui/agent-card.json', 'application/json'],
    ['a2ui/agent-webview.js', 'text/javascript'],
    ['a2ui/image/shrimpchowmein.jpeg', 'image/jpeg'],
    ['a2ui/image/mapotofu.jpeg', 'image/jpeg'],
    ['a2ui/image/beefbroccoli.jpeg', 'image/jpeg'],
    ['a2ui/image/springrolls.jpeg', 'image/jpeg'],
    ['a2ui/image/kungpao.jpeg', 'image/jpeg'],
  ])

  async aboutToAppear() {
    await this.requestPermissionFn();
    const context = getContext(this);
    this.audioFilePath = `${context.filesDir}/record.pcm}`;
    this.wavFilePath = `${context.filesDir}/record.wav`;
    hilog.info(0xff00, TAG, '%{public}s,%{public}s', `Aduio file will be save to: ${this.audioFilePath}`);
  }

  private isRecording: boolean = false;
  private isLoading: boolean = false;

  // 开始持续录音
  async startRecording() {
    this.isRecording = true;
    this.isLoading = true;
    try {
      // 确保旧文件删除，避免追加内容
      if (fs.accessSync(this.audioFilePath)) {
        fs.unlink(this.audioFilePath);
      }
      const audioCapturerInfo: audio.AudioCapturerInfo = {
        source: audio.SourceType.SOURCE_TYPE_MIC,
        capturerFlags: 0
      }
      const audioStreamInfo: audio.AudioStreamInfo = {
        samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_16000,
        channels: audio.AudioChannel.CHANNEL_2,
        sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
        encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
      }
      const capturerOptions: audio.AudioCapturerOptions = {
        streamInfo: audioStreamInfo,
        capturerInfo: audioCapturerInfo
      }

      // 打开录音文件
      const audioCapturer = await audio.createAudioCapturer(capturerOptions);
      this.fileDesciptor = fs.openSync(this.audioFilePath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE).fd;

      // 注册数据callback
      this.buffferOffset = 0;
      audioCapturer.on('readData', (buffer) => {
        if (this.isRecording) {
          fs.writeSync(this.fileDesciptor, buffer, { offset: this.buffferOffset, length: buffer.byteLength });
          this.buffferOffset += buffer.byteLength;
        }
      });

      // 开始录制
      audioCapturer.start();
    } catch (err) {
      hilog.info(0xff00, TAG, '%{public}s,%{public}s', `录音初始化失败：${JSON.stringify(err)}`);
      this.isRecording = false;
      this.isLoading = false;
    }
  }

  // 停止录音并处理
  async stopRecordAndProcess() :Promise<string> {
    if (!this.isRecording && !this.audioCapturer) {
      return '';
    }
    this.isRecording = false; //停止循环读取
    this.isLoading = true;
    try {
      if (this.audioCapturer) {
        await this.audioCapturer.stop();
        await this.audioCapturer.release();
        this.audioCapturer = null;
      }
      if (this.fileDesciptor !== -1) {
        fs.closeSync(this.fileDesciptor);
        this.fileDesciptor = -1;
      }

      hilog.info(0xff00, TAG, '%{public}s,%{public}s', 'stop record, Processing');
      const params: WavHeaderParams = {
        sampleRate: audio.AudioSamplingRate.SAMPLE_RATE_16000,
        numChannels: audio.AudioChannel.CHANNEL_2,
        bitsPerSample: 16
      }

      Utils.convertPCM2Wave(this.audioFilePath, this.wavFilePath, params);

      // 语音转文字
      const recognizeText = await this.aiService.speechToText(this.wavFilePath, getContext(this));
      if (recognizeText !== '') {
        hilog.info(0xff00, TAG, '%{public}s,%{public}s', `recognize result:${recognizeText}`);
      }
      return recognizeText;
    } catch (err) {
    }
    return '';
  }

  /* UI 构建  */
  build() {
    Column() {
      /* A2UI Web 内容（本地 index.html）  */
      Web({ src: 'https://www.localA2UIywh.com/index.html', controller: this.controller })
        .fileAccess(true)
        .geolocationAccess(true)
        .javaScriptAccess(true)          // 允许 JS
        .domStorageAccess(true)          // 允许 localStorage
        .onControllerAttached(() => {
        })
        .onInterceptRequest((event) => {
          console.info(`[A2UI] InterceptRequest enters`);
          if (!event) {
            return;
          }
          console.info(`[A2UI] getRequestUrl:${event.request.getRequestUrl()}`);
          if (this.schemeMap.has(event.request.getRequestUrl())) {
            let railFileName: string = this.schemeMap.get(event.request.getRequestUrl())!;
            console.info(`[A2UI] rawfilename:${railFileName}`);
            let mimeType = this.mimeType.get(railFileName);
            console.info(`[A2UI] mimeType:${mimeType}`);
            if (typeof mimeType === 'string') {
              console.info(`[A2UI] begin setResponse`);
              let response = new WebResourceResponse();
              response.setResponseData($rawfile(railFileName));
              response.setResponseEncoding('utf-8');
              response.setResponseMimeType(mimeType);
              response.setResponseCode(200);
              response.setReasonMessage('OK');
              response.setResponseIsReady(true);
              return response;
            }
          }
          return null;
        })
        .onPageBegin(()=> {
          try {
            this.controller.registerJavaScriptProxy(this, "Speech", ["startRecording", "stopRecordAndProcess"])
          } catch (error) {
          }
        })
        .width('100%')
        .height('100%')
        .onPageEnd(() => {
          console.info('[A2UI] 本地 index.html 加载完成');
          // this.setupJSProxy();           // 页面加载后注册代理
        })
        .onErrorReceive((event) => {
          console.error('[A2UI] 页面错误', event.error);
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}