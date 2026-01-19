/**
 * InMemoryTaskStore - 内存任务存储
 * 与原 @a2a-js/sdk 的 InMemoryTaskStore 保持相同接口
 */
export class InMemoryTaskStore {
    constructor() {
        this.tasks = new Map();
    }

    /**
     * 获取任务
     * @param {string} taskId 
     * @returns {Promise<Object|null>}
     */
    async get(taskId) {
        return this.tasks.get(taskId) || null;
    }

    /**
     * 保存任务
     * @param {Object} task 
     */
    async save(task) {
        this.tasks.set(task.id, task);
    }

    /**
     * 删除任务
     * @param {string} taskId 
     */
    async delete(taskId) {
        this.tasks.delete(taskId);
    }

    /**
     * 列出所有任务
     * @returns {Promise<Array>}
     */
    async list() {
        return Array.from(this.tasks.values());
    }

    /**
     * 清空所有任务
     */
    async clear() {
        this.tasks.clear();
    }
}
