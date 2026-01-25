export class QueueManager {
    private queue: any[] = [];
    private isProcessing = false;

    async addToQueue(operation: any) {
        this.queue.push(operation);
        this.processQueue();
    }

    private async processQueue() {
        if (this.isProcessing || this.queue.length === 0) return;
        this.isProcessing = true;

        try {
            const operation = this.queue.shift();
            // Process operation (e.g., sync to backend if online)
            console.log('Processing operation:', operation);

            // If success
            // ...

            // If failed, maybe retry or put back
        } catch (error) {
            console.error('Queue processing error:', error);
        } finally {
            this.isProcessing = false;
            if (this.queue.length > 0) {
                this.processQueue();
            }
        }
    }
}

export const queueManager = new QueueManager();
