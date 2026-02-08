import { env } from "$env/dynamic/private";

/**
 * Lightweight K8s API client.
 * In-cluster: uses service account token and CA from mounted paths.
 * Development: uses KUBECONFIG or kubectl proxy.
 */

interface K8sListResponse<T> {
  kind: string;
  items: T[];
  metadata: { resourceVersion?: string };
}

export class K8sClient {
  private baseUrl: string;
  private token: string | null;
  private available: boolean | null = null;
  private namespace: string;

  constructor(namespace?: string) {
    // Get namespace from parameter, environment variable, or default
    this.namespace = namespace ?? env.K8S_NAMESPACE ?? "gitlab-runners";
    const inCluster = env.KUBERNETES_SERVICE_HOST;
    if (inCluster) {
      this.baseUrl = `https://${env.KUBERNETES_SERVICE_HOST}:${env.KUBERNETES_SERVICE_PORT}`;
      // Token will be read lazily
      this.token = null;
    } else {
      // Development: assume kubectl proxy on localhost:8001
      this.baseUrl = env.K8S_PROXY_URL ?? "http://localhost:8001";
      this.token = null;
    }
  }

  async isAvailable(): Promise<boolean> {
    if (this.available !== null) return this.available;
    try {
      const response = await this.fetch("/api/v1/namespaces/" + this.namespace);
      this.available = response.ok;
    } catch {
      this.available = false;
    }
    return this.available;
  }

  getNamespace(): string {
    return this.namespace;
  }

  resetAvailability() {
    this.available = null;
  }

  private async getToken(): Promise<string | null> {
    if (this.token) return this.token;
    try {
      // In-cluster: read from mounted service account
      const fs = await import("fs/promises");
      this.token = (
        await fs.readFile(
          "/var/run/secrets/kubernetes.io/serviceaccount/token",
          "utf-8",
        )
      ).trim();
      return this.token;
    } catch {
      return null;
    }
  }

  private async fetch(path: string): Promise<Response> {
    const headers: Record<string, string> = {};
    const token = await this.getToken();
    if (token) {
      headers["Authorization"] = `Bearer ${token}`;
    }
    return globalThis.fetch(`${this.baseUrl}${path}`, {
      headers,
      signal: AbortSignal.timeout(10000),
    });
  }

  private async request<T>(path: string): Promise<T> {
    const response = await this.fetch(path);
    if (!response.ok) {
      throw new Error(
        `K8s API error: ${response.status} ${response.statusText}`,
      );
    }
    return response.json() as Promise<T>;
  }

  async listPods(): Promise<K8sPod[]> {
    const data = await this.request<K8sListResponse<K8sPod>>(
      `/api/v1/namespaces/${this.namespace}/pods`,
    );
    return data.items;
  }

  async listDeployments(): Promise<K8sDeployment[]> {
    const data = await this.request<K8sListResponse<K8sDeployment>>(
      `/apis/apps/v1/namespaces/${this.namespace}/deployments`,
    );
    return data.items;
  }

  async listHPAs(): Promise<K8sHPA[]> {
    const data = await this.request<K8sListResponse<K8sHPA>>(
      `/apis/autoscaling/v2/namespaces/${this.namespace}/horizontalpodautoscalers`,
    );
    return data.items;
  }

  async listEvents(limit: number = 50): Promise<K8sEvent[]> {
    const data = await this.request<K8sListResponse<K8sEvent>>(
      `/api/v1/namespaces/${this.namespace}/events?limit=${limit}&fieldSelector=type!=Normal`,
    );
    return data.items;
  }
}

export interface K8sPod {
  metadata: {
    name: string;
    namespace: string;
    labels: Record<string, string>;
    creationTimestamp: string;
  };
  status: {
    phase: string;
    containerStatuses?: Array<{
      name: string;
      ready: boolean;
      restartCount: number;
      state: Record<string, unknown>;
    }>;
  };
}

export interface K8sDeployment {
  metadata: { name: string; namespace: string };
  spec: { replicas: number };
  status: {
    replicas: number;
    readyReplicas: number;
    availableReplicas: number;
    updatedReplicas: number;
  };
}

export interface K8sHPA {
  metadata: { name: string; namespace: string };
  spec: {
    minReplicas: number;
    maxReplicas: number;
    metrics: Array<{
      type: string;
      resource?: {
        name: string;
        target: { type: string; averageUtilization?: number };
      };
    }>;
  };
  status: {
    currentReplicas: number;
    desiredReplicas: number;
    currentMetrics: Array<{
      type: string;
      resource?: {
        name: string;
        current: { averageUtilization?: number; averageValue?: string };
      };
    }>;
  };
}

export interface K8sEvent {
  metadata: { name: string; creationTimestamp: string };
  type: string;
  reason: string;
  message: string;
  involvedObject: { kind: string; name: string };
  count: number;
  lastTimestamp: string;
}

export const k8sClient = new K8sClient();
