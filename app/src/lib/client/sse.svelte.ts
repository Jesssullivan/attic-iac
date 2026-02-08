/**
 * Client-side SSE consumer with auto-reconnect
 */

type EventCallback = (data: unknown) => void;

export class SSEClient {
  private source: EventSource | null = null;
  private listeners = new Map<string, EventCallback[]>();
  private reconnectDelay = 1000;
  private maxReconnectDelay = 30000;
  private currentDelay = 1000;
  private url: string;

  connected = $state(false);

  constructor(url: string) {
    this.url = url;
  }

  connect() {
    if (this.source) return;

    this.source = new EventSource(this.url);

    this.source.onopen = () => {
      this.connected = true;
      this.currentDelay = this.reconnectDelay;
    };

    this.source.onerror = () => {
      this.connected = false;
      this.source?.close();
      this.source = null;

      // Auto-reconnect with exponential backoff
      setTimeout(() => this.connect(), this.currentDelay);
      this.currentDelay = Math.min(
        this.currentDelay * 2,
        this.maxReconnectDelay,
      );
    };

    // Register all listeners on the new source
    for (const [event, callbacks] of this.listeners) {
      for (const cb of callbacks) {
        this.source.addEventListener(event, (e) => {
          try {
            cb(JSON.parse((e as MessageEvent).data));
          } catch {
            cb((e as MessageEvent).data);
          }
        });
      }
    }
  }

  on(event: string, callback: EventCallback) {
    if (!this.listeners.has(event)) {
      this.listeners.set(event, []);
    }
    this.listeners.get(event)!.push(callback);

    // If already connected, add to existing source
    if (this.source) {
      this.source.addEventListener(event, (e) => {
        try {
          callback(JSON.parse((e as MessageEvent).data));
        } catch {
          callback((e as MessageEvent).data);
        }
      });
    }
  }

  disconnect() {
    this.source?.close();
    this.source = null;
    this.connected = false;
    this.listeners.clear();
  }
}
