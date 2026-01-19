/**
 * A2A SDK 浏览器适配层入口
 * 保持 A2A 协议能力，用 Native Bridge 替代 HTTP 传输
 */

export { BrowserRequestHandler } from './request-handler.js';
export { InMemoryTaskStore } from './task-store.js';
export { NativeTransport, nativeTransport } from './native-transport.js';
export { agentMessageBus } from '../native-bridge.js';
