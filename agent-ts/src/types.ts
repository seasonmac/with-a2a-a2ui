export interface Restaurant {
  name: string;
  detail: string;
  imageUrl: string;
  rating: string;
  infoLink: string;
  address: string;
}

export interface ToolContext {
  state: Record<string, unknown>;
}

export interface AgentSkill {
  id: string;
  name: string;
  description: string;
  tags: string[];
  examples: string[];
}

export interface UIEventAction {
  actionName: string;
  context: Record<string, unknown>;
}

export interface MessagePart {
  type: 'text' | 'data';
  text?: string;
  data?: Record<string, unknown>;
}

export interface Task {
  id: string;
  context_id: string;
  state: TaskState | string;
}

export enum TaskState {
  WORKING = 'working',
  COMPLETED = 'completed',
  INPUT_REQUIRED = 'input_required',
}

export interface StreamResult {
  is_task_complete: boolean;
  content?: string;
  updates?: string;
}

export interface A2UIMessage {
  beginRendering?: {
    surfaceId: string;
    root: string;
    styles?: {
      primaryColor?: string;
      font?: string;
    };
  };
  surfaceUpdate?: {
    surfaceId: string;
    components: A2UIComponent[];
  };
  dataModelUpdate?: {
    surfaceId: string;
    path?: string;
    contents: A2UIDataEntry[];
  };
  deleteSurface?: {
    surfaceId: string;
  };
}

export interface A2UIComponent {
  id: string;
  weight?: number;
  component: Record<string, unknown>;
}

export interface A2UIDataEntry {
  key: string;
  valueString?: string;
  valueNumber?: number;
  valueBoolean?: boolean;
  valueMap?: A2UIDataEntry[];
}
