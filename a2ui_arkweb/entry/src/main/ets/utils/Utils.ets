import { hilog } from "@kit.PerformanceAnalysisKit";
import fs, {ReadOptions} from '@ohos.file.fs';
import { buffer, util} from '@kit.ArkTS';

const TAG = 'Uils';

export interface WavHeaderParams {
  sampleRate:number;        // 采样率
  numChannels:number;       // 声道数
  bitsPerSample:number;     // 采样位数
}
export default class Utils {
  public static async fileToBase64(filePath:string) :Promise<string> {
    try{
      const file = await fs.open(filePath, fs.OpenMode.READ_ONLY);
      const stat = await fs.stat(filePath);
      const buffer = new ArrayBuffer(stat.size);
      await fs.read(file.fd, buffer);
      await fs.close(file.fd);

      // Base64Helper 的构造函数
      const base64Helper = new util.Base64Helper();
      // 通过输入参数编码后输出 Unint8Array 对象
      const unit8Data = base64Helper.encodeSync(new Uint8Array(buffer.slice(0,buffer.byteLength)));
      // 将直接数组解码为字符串，格式为 utf-8
      let textDecoder= util.TextDecoder.create('utf-8', { ignoreBOM: true });
      return textDecoder.decodeWithStream(unit8Data);
    }catch (err) {
      hilog.info(0xff00, TAG, '%{public}s,%{public}s',`Failed to read file and convert to Base64:${JSON.stringify(err)}`);
      throw new Error(`File to Base64 convert failed for path ${filePath}`);
    }
  }

  public static generateUUID():string {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxx'.replace(/[xy]/g,(c)=>{
      const r = Math.random()*16|0;
      const v =c ==='x'?r:(r&0x3 | 0x8);
      return v.toString(16);
    })
  }
  public static convertPCM2Wave(pcmFilePath:string,wavFilePath:string,params:WavHeaderParams) :boolean {
    try {
      const pcmFile = fs.openSync(pcmFilePath, fs.OpenMode.READ_ONLY);
      const wavFile = fs.openSync(wavFilePath, fs.OpenMode.CREATE| fs.OpenMode.READ_WRITE);

      const stats = fs.statSync(pcmFile.fd);
      const audioDataSize = stats.size;

      const byteRate = params.sampleRate * params.numChannels *(params.bitsPerSample/8);

      const totalDataLen = audioDataSize + 44 - 8;
      Utils.writeWaveFileHeader(wavFile, totalDataLen, audioDataSize, params, byteRate);

      Utils.writePCMData(pcmFile, wavFile, audioDataSize);

      fs.closeSync(pcmFile);
      fs.closeSync(wavFile);
      return true;
    }catch (err) {
      hilog.info(0xff00, TAG, '%{public}s,%{public}s',`Failed to conver PCM to Wave:${JSON.stringify(err)}`);
      return false;
    }
  }
  private static writePCMData(inFile:fs.File, outFile:fs.File, audioDataSize:number){
    let readSize = 0;
    let data= new ArrayBuffer(audioDataSize);
    let readOptions:ReadOptions = {
      offset: readSize,
      length:audioDataSize
    };
    let readLen = fs.readSync(inFile.fd, data, readOptions);
    while(readLen > 0) {
      readSize += readLen;
      fs.writeSync(outFile.fd, data,{length:readLen});
      readOptions.offset = readSize;
      readLen = fs.readSync(inFile.fd, data, readOptions);
    }
    fs.closeSync(inFile.fd);
    fs.closeSync(outFile.fd);
  }
  private static writeString(view: DataView, offset:number, str:string) {
    for(let i = 0; i<str.length; i++) {
      view.setUint8(offset+i, str.charCodeAt(i));
    }
  }
  private static writeWaveFileHeader(out:fs.File, audioDataSize:number, totalDataLen:number, params:WavHeaderParams, byteRate:number) {
    const header = new ArrayBuffer(44);
    const dv = new DataView(header);
    // 写入 RIFF 块
    Utils.writeString(dv,0 ,'RIFF');
    dv.setInt32(4,totalDataLen,true);
    Utils.writeString(dv,8 ,'WAVE');
    // 写入 FMT 块
    Utils.writeString(dv,12,'fmt');
    dv.setUint32(16,16,true); // fmt 块大小
    dv.setUint16(20,1,true); // 格式类别（PCM）
    dv.setUint16(22,params.numChannels, true); // 通道数
    dv.setUint32(24,params.sampleRate,true); // 采样率
    dv.setUint32(28,byteRate,true); // 码率
    dv.setUint16(32,params.numChannels*params.bitsPerSample/8,true); // BlockAlign
    dv.setUint16(34,params.bitsPerSample ,true); // 位深

    // 写入 data 块
    Utils.writeString(dv,36,'data');
    dv.setUint32(40, audioDataSize,true);
    fs.writeSync(out.fd,new Uint8Array(header).buffer, {length:44});
  }
}