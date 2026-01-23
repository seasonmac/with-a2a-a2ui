export interface http_headers {
  "X-Api-App-Key": string;
  "X-Api-Access-Key": string;
  "X-Api-Resource-Id": string;
  "X-Api-Request-Id": string;
  "X-Api-Sequence": string;
  "Content-Type": string;
}

export interface IAudioData {
  data: string;
}

export interface IUserInfo {
  uid: string;
}

export interface IRequestParams {
  model_name: string;
}

export interface IRequestPayload {
  user: IUserInfo;
  audio: IAudioData;
  request: IRequestParams;
}

export interface IAudioInfo{
  duration:number;
}
export interface IAdditions{
  duration:string;
}

export interface IUtterances {
  text: string;
}

export interface IResult {
  additions: IAdditions;
  text: string;
  utterances?: Array<IUtterances>;
}

export interface IResponseText {
  audio_info:IAudioInfo,
  result: IResult
}

export const enum VoiceRecognizeErrCode {
  SUCCESS = 20000000,
  SLIENT_VOICE_ERR = 20000003,
  INVALID_PARAMS_ERR = 45000001,
  EMPTY_FILE_ERR = 45000002,
  FILE_FORMAT_ERR = 45000151,
  SERVER_BUSY_ERR = 55000031
}

export interface IConversation {
  role: string;
  content: string;
}

interface IChatMessage {
  content:string,
  reasoning_content:string,
  role: string
}

interface IChoicesMessage {
  finish_reason:string,
  index:number,
  logprobs: null,
  message:IChatMessage
}

interface IPromptTokensDetails {
  cached_tokens: number;
}

interface ICompletionTokensDetails {
  reasoning_tokens: number;
}

interface IChatUsage{
  completion_tokens: number,
  prompt_tokens: number,
  total_tokens: number,
  prompt_tokens_details: IPromptTokensDetails,
  completion_tokens_details: ICompletionTokensDetails
}


export interface IChatResponse {
  choices:Array<IChoicesMessage>,
  created:number,
  id:string,
  model:string,
  service_tier:string,
  object:string,
  usage:IChatUsage
}

