import type { RunnerInfo } from "$lib/types";

let runners = $state<RunnerInfo[]>([]);
let loading = $state(false);
let error = $state<string | null>(null);

export const runnersStore = {
  get list() {
    return runners;
  },
  get loading() {
    return loading;
  },
  get error() {
    return error;
  },
  get count() {
    return runners.length;
  },
  getByName(name: string): RunnerInfo | undefined {
    return runners.find((r) => r.name === name);
  },
  getByType(type: string): RunnerInfo[] {
    return runners.filter((r) => r.type === type);
  },
  set(data: RunnerInfo[]) {
    runners = data;
    error = null;
  },
  setLoading(state: boolean) {
    loading = state;
  },
  setError(msg: string) {
    error = msg;
    loading = false;
  },
};
